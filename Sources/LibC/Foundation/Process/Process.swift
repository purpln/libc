public func processorCoresCount() -> Int {
#if os(macOS) || os(iOS)
    var count: Int32 = -1
    var mib: [Int32] = [CTL_HW, HW_NCPU]
    var countSize = MemoryLayout<Int32>.size
    let status = sysctl(&mib, UInt32(mib.count), &count, &countSize, nil, 0)
    guard status == 0 else {
        return 0
    }
    return Int(count)
#elseif os(Windows)
    var siInfo = SYSTEM_INFO()
    GetSystemInfo(&siInfo)
    return Int(siInfo.dwNumberOfProcessors)
#elseif os(Linux) || os(Android)
    return Int(sysconf(Int32(_SC_NPROCESSORS_CONF)))
#else
    return 1
#endif
}

public func activeCoresCount() -> Int {
#if os(macOS) || os(iOS)
    var count: Int32 = -1
    var mib: [Int32] = [CTL_HW, HW_AVAILCPU]
    var countSize = MemoryLayout<Int32>.size
    let status = sysctl(&mib, UInt32(mib.count), &count, &countSize, nil, 0)
    guard status == 0 else {
        return 0
    }
    return Int(count)
#elseif os(Linux) || os(Android)
#if os(Linux)
    if let fsCount = fsCoreCount() {
        return fsCount
    }
#endif
    return Int(sysconf(Int32(_SC_NPROCESSORS_ONLN)))
#elseif os(Windows)
    var sysInfo = SYSTEM_INFO()
    GetSystemInfo(&sysInfo)
    return sysInfo.dwActiveProcessorMask.nonzeroBitCount
#else
    return 0
#endif
}

public func physicalMemory() -> UInt64 {
#if os(macOS) || os(iOS)
    var memory: UInt64 = 0
    var memorySize = MemoryLayout<UInt64>.size
    let name = "hw.memsize"
    return name.withCString {
        let status = sysctlbyname($0, &memory, &memorySize, nil, 0)
        if status == 0 {
            return memory
        }
        return 0
    }
#elseif os(Windows)
    var totalMemoryKB: ULONGLONG = 0
    guard GetPhysicallyInstalledSystemMemory(&totalMemoryKB) else {
        return 0
    }
    return totalMemoryKB * 1024
#elseif os(Linux) || os(Android)
    var memory = sysconf(Int32(_SC_PHYS_PAGES))
    memory *= sysconf(Int32(_SC_PAGESIZE))
    return UInt64(memory)
#else
    return 0
#endif
}

public func hostname() -> String {
#if os(Windows)
    var dwLength: DWORD = 0
    _ = GetComputerNameExW(ComputerNameDnsHostname, nil, &dwLength)
    return withUnsafeTemporaryAllocation(of: WCHAR.self, capacity: Int(dwLength)) {
        dwLength -= 1 // null-terminator reservation
        guard GetComputerNameExW(ComputerNameDnsHostname, $0.baseAddress!, &dwLength) else {
            return "localhost"
        }
        return String(decodingCString: $0.baseAddress!, as: UTF16.self)
    }
#elseif os(WASI) // WASI does not have uname
    return "localhost"
#else
    let capacity = 1024
    return withUnsafeTemporaryAllocation(of: CChar.self, capacity: capacity + 1) {
        guard gethostname($0.baseAddress!, numericCast(capacity)) == 0 else {
            return "localhost"
        }
        return String(cString: $0.baseAddress!)
    }
#endif
}

public func operatingSystemVersion() -> (major: Int, minor: Int, patch: Int, build: String?) {
#if os(macOS) || os(iOS) || os(Linux) || os(Android)
    var uts: utsname = utsname()
    do {
        try nothingOrErrno(retryOnInterrupt: false, {
            uname(&uts)
        }).get()
    } catch {
        return (major: -1, minor: 0, patch: 0, build: nil)
    }
    
    var string = withUnsafePointer(to: &uts.release.0, { String(cString:  $0) })
    var build: String?
    
    if let index = string.firstIndex(of: "-") {
        if let index = string.index(index, offsetBy: 1, limitedBy: string.endIndex) {
            build = String(string[index ..< string.endIndex])
        }
        string = String(string[string.startIndex ..< index])
    }
    let version = string.split(separator: ".")
        .compactMap { Int($0) }
    let major = version.count >= 1 ? version[0] : -1
    let minor = version.count >= 2 ? version[1] : 0
    let patch = version.count >= 3 ? version[2] : 0
    return (major: major, minor: minor, patch: patch, build: build)
#elseif os(Windows)
    guard let osVersionInfo = _rawOSVersion else {
        return (major: -1, minor: 0, patch: 0, build: nil)
    }
    
    return (
        major: Int(osVersionInfo.dwMajorVersion),
        minor: Int(osVersionInfo.dwMinorVersion),
        patch: Int(osVersionInfo.dwBuildNumber),
        build: nil
    )
#else
    return (major: -1, minor: 0, patch: 0, build: nil)
#endif
}

public func operatingSystemVersionString() -> String {
#if os(macOS) || os(iOS)
    var (platform, version) = readOSRelease()
    
    if version.major != -1 {
        platform += " \(version.major).\(version.minor).\(version.patch)"
        if let build = version.build {
            platform += "-\(build)"
        }
    }
    
    return platform
#elseif os(Linux)
    if let name = readOSRelease()?["PRETTY_NAME"] {
        return name
    } else {
        var platform = "Linux"
        
        let version = operatingSystemVersion()
        if version.major != -1 {
            platform += " \(version.major).\(version.minor).\(version.patch)"
            if let build = version.build {
                platform += "-\(build)"
            }
        }
        
        return platform
    }
#elseif os(Windows)
    guard let osVersionInfo = self._rawOSVersion else {
        return "Windows"
    }
    
    // Windows has no canonical way to turn the fairly complex `RTL_OSVERSIONINFOW` version info into a string. We
    // do our best here to construct something consistent. Unfortunately, to provide a useful result, this requires
    // hardcoding several of the somewhat ambiguous values in the table provided here:
    //  https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/ns-wdm-_osversioninfoexw#remarks
    let release = switch (osVersionInfo.dwMajorVersion, osVersionInfo.dwMinorVersion, osVersionInfo.dwBuildNumber) {
    case (5, 0, _): "2000"
    case (5, 1, _): "XP"
    case (5, 2, _) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "XP Professional x64"
    case (5, 2, _) where osVersionInfo.wSuiteMask == VER_SUITE_WH_SERVER: "Home Server"
    case (5, 2, _): "Server 2003"
    case (6, 0, _) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "Vista"
    case (6, 0, _): "Server 2008"
    case (6, 1, _) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "7"
    case (6, 1, _): "Server 2008 R2"
    case (6, 2, _) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "8"
    case (6, 2, _): "Server 2012"
    case (6, 3, _) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "8.1"
    case (6, 3, _): "Server 2012 R2" // We assume the "10,0" numbers in the table for this are a typo
    case (10, 0, ..<22000) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "10"
    case (10, 0, 22000...) where osVersionInfo.wProductType == VER_NT_WORKSTATION: "11"
    case (10, 0, _): "Server 2019" // The table gives identical values for 2016 and 2019, so we just assume 2019 here
    case let (maj, min, _): "Unknown (\(maj).\(min))" // If all else fails, just give the raw version number
    }
    // For now we ignore the `szCSDVersion`, `wServicePackMajor`, and `wServicePackMinor` values.
    return "Windows \(release) (build \(osVersionInfo.dwBuildNumber))"
#elseif os(Android)
    return systemProperty(named: "ro.build.description") ?? "Android"
#elseif os(WASI)
    return "WASI"
#else
    return "Unknown"
#endif
}
