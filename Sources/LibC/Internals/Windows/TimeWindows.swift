#if os(Windows)

@usableFromInline
internal let _CLOCK_REALTIME: Int = 0

@usableFromInline
internal let epoch: UInt64 = 11644473600

internal extension FILETIME {
    var seconds: UInt64 {
        var time = ULARGE_INTEGER()
        
        time.LowPart = dwLowDateTime
        time.HighPart = dwHighDateTime
        
        return time.QuadPart / 10_000_000 - epoch
    }
}

@inline(__always)
@usableFromInline
@discardableResult
internal func gettimeofday(
    _ tp: UnsafeMutablePointer<timeval>!,
    _ tzp: UnsafeMutableRawPointer!
) -> CInt {
    var system_time = SYSTEMTIME()
    var file_time = FILETIME()
    
    GetSystemTime(&system_time)
    SystemTimeToFileTime(&system_time, &file_time)
    
    tp.pointee.tv_sec = CInt(file_time.seconds)
    tp.pointee.tv_usec = CInt(system_time.wMilliseconds) * 100
    
    return 0
}

@inline(__always)
@usableFromInline
@discardableResult
internal func clock_gettime(
    _ type: Int,
    _ ts: UnsafeMutablePointer<timespec>!
) -> CInt {
    var system_time = SYSTEMTIME()
    var file_time = FILETIME()
    
    GetSystemTime(&system_time)
    SystemTimeToFileTime(&system_time, &file_time)
    
    ts.pointee.tv_sec = Int64(file_time.seconds)
    ts.pointee.tv_nsec = CInt(system_time.wMilliseconds) % 10_000_000 * 100
    
    return 0
}

#endif
