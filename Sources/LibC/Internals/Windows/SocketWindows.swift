#if os(Windows)
@inline(__always)
internal func socket(
    _ family: CInt,
    _ type: CInt,
    _ protocol: CInt
) -> CInt {
    let result = socket(family, type, `protocol`) as SOCKET
    guard result != INVALID_SOCKET else { return -1 }
    return CInt(result)
}

@inline(__always)
internal func closesocket(
    _ descriptor: CInt
) -> CInt {
    closesocket(SOCKET(descriptor))
}

@inline(__always)
internal func inet_ntop(
    _ family: CInt,
    _ address: UnsafeRawPointer?,
    _ value: UnsafeMutablePointer<CChar>?,
    _ length: socklen_t
) -> UnsafePointer<CChar>? {
    inet_ntop(family, address, value, Int(length))
}

@inline(__always)
internal func getsockopt(
    _ descriptor: CInt,
    _ level: CInt,
    _ name: CInt,
    _ value: UnsafeMutableRawPointer?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
    getsockopt(SOCKET(descriptor), level, name, value, length)
}
@inline(__always)
internal func setsockopt(
    _ descriptor: CInt,
    _ level: CInt,
    _ name: CInt,
    _ value: UnsafeRawPointer?,
    _ length: socklen_t
) -> CInt {
    setsockopt(SOCKET(descriptor), level, name, value, length)
}

@inline(__always)
internal func getsockname(
    _ descriptor: CInt,
    _ name: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
    getsockname(SOCKET(descriptor), name, length)
}

@inline(__always)
internal func getpeername(
    _ descriptor: CInt,
    _ name: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
    getpeername(SOCKET(descriptor), name, length)
}

@inline(__always)
internal func accept(
    _ descriptor: CInt,
    _ address: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
    let result = accept(SOCKET(descriptor), address, length)
    guard result != INVALID_SOCKET else { return -1 }
    return CInt(result)
}

@inline(__always)
internal func bind(
    _ descriptor: CInt,
    _ address: UnsafePointer<sockaddr>?,
    _ length: socklen_t
) -> CInt {
    bind(SOCKET(descriptor), address, length)
}

@inline(__always)
internal func connect(
    _ descriptor: CInt,
    _ address: UnsafePointer<sockaddr>?,
    _ length: socklen_t
) -> CInt {
    connect(SOCKET(descriptor), address, length)
}

@inline(__always)
internal func listen(
    _ descriptor: CInt,
    _ backlog: CInt
) -> CInt {
    listen(SOCKET(descriptor), backlog)
}

@inline(__always)
internal func recv(
    _ descriptor: CInt,
    _ buffer: UnsafeMutableRawPointer?,
    _ size: Int,
    _ flags: CInt
) -> Int {
    Int(recv(SOCKET(descriptor), buffer, numericCast(size), flags))
}

@inline(__always)
internal func recvfrom(
    _ descriptor: CInt,
    _ buffer: UnsafeMutableRawPointer?,
    _ size: Int,
    _ flags: CInt,
    _ address: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> Int {
    Int(recvfrom(SOCKET(descriptor), buffer, numericCast(size), flags, address, length))
}


@inline(__always)
internal func send(
    _ descriptor: CInt,
    _ buffer: UnsafeRawPointer?,
    _ size: Int,
    _ flags: CInt
) -> Int {
    Int(send(SOCKET(descriptor), buffer, numericCast(size), flags))
}

@inline(__always)
internal func sendto(
    _ descriptor: CInt,
    _ buffer: UnsafeRawPointer?,
    _ size: Int,
    _ flags: CInt,
    _ address: UnsafePointer<sockaddr>?,
    _ length: socklen_t
) -> Int {
    Int(sendto(SOCKET(descriptor), buffer, numericCast(size), flags, address, length))
}

#endif
