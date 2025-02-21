#if os(Windows)
internal var _rawOSVersion: RTL_OSVERSIONINFOEXW? {
    guard let ntdll = "ntdll.dll".withCString(encodedAs: UTF16.self, LoadLibraryW) else {
        return nil
    }
    defer { FreeLibrary(ntdll) }
    typealias RTLGetVersionTy = @convention(c) (UnsafeMutablePointer<RTL_OSVERSIONINFOEXW>) -> NTSTATUS
    guard let pfnRTLGetVersion = unsafeBitCast(GetProcAddress(ntdll, "RtlGetVersion"), to: Optional<RTLGetVersionTy>.self) else {
        return nil
    }
    var osVersionInfo = RTL_OSVERSIONINFOEXW()
    osVersionInfo.dwOSVersionInfoSize = DWORD(MemoryLayout<RTL_OSVERSIONINFOEXW>.size)
    guard pfnRTLGetVersion(&osVersionInfo) == 0 else {
        return nil
    }
    return osVersionInfo
}
#endif
