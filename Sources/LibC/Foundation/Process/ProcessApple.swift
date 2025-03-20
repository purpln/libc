#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
private func getSysCtlString(_ name: String) throws -> String {
    let bytes = try [UInt8](unsafeUninitializedCapacity: 1024) { buffer, count in
        count = 1024
        try nothingOrErrno(retryOnInterrupt: false, {
            sysctlbyname(name, buffer.baseAddress, &count, nil, 0)
        }).get()
    }
    return String(decoding: bytes, as: UTF8.self)
}

internal func readOSRelease() throws -> (platform: String, version: (major: Int, minor: Int, patch: Int, build: String?)) {
#if os(macOS)
    let platform = "macOS"
#elseif os(iOS)
    let platform = "iOS"
#elseif os(watchOS)
    let platform = "watchOS"
#elseif os(tvOS)
    let platform = "tvOS"
#elseif os(visionOS)
    let platform = "visionOS"
#endif
    
    let version = try getSysCtlString("kern.osproductversion")
        .split(separator: ".")
        .compactMap { Int($0) }
    let major = version.count >= 1 ? version[0] : -1
    let minor = version.count >= 2 ? version[1] : 0
    let patch = version.count >= 3 ? version[2] : 0
    
    let build = try getSysCtlString("kern.osversion")
    
    return (platform, (major, minor, patch, build))
}
#endif
