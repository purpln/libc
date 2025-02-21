#if os(macOS) || os(iOS)
private func getSysCtlString(_ name: String) -> String? {
    withUnsafeTemporaryAllocation(byteCount: 256, alignment: 16) { buffer in
        
        var len = buffer.count
        
        nothingOrErrno(retryOnInterrupt: false, {
            sysctlbyname(name, buffer.baseAddress, &len, nil, 0)
        })
        
        return String(validatingCString: buffer.baseAddress!.assumingMemoryBound(to: CChar.self))
    }
}

internal func readOSRelease() -> (platform: String, version: (major: Int, minor: Int, patch: Int, build: String?)) {
#if os(macOS)
    var platform = "macOS"
#elseif os(iOS)
    var platform = "iOS"
#elseif os(watchOS)
    var platform = "watchOS"
#elseif os(tvOS)
    var platform = "tvOS"
#elseif os(visionOS)
    var platform = "visionOS"
#endif
    
    let version = getSysCtlString("kern.osproductversion")?
        .split(separator: ".")
        .compactMap { Int($0) } ?? []
    let major = version.count >= 1 ? version[0] : -1
    let minor = version.count >= 2 ? version[1] : 0
    let patch = version.count >= 3 ? version[2] : 0
    
    let build = getSysCtlString("kern.osversion")
    
    return (platform, (major, minor, patch, build))
}
#endif
