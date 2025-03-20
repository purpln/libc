#if os(Windows)

@inline(__always)
internal func accept(
    _ descriptor: CInt,
    _ address: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
    CInt(accept(SOCKET(descriptor), address!, length))
}

@inline(__always)
internal func bind(
    _ descriptor: CInt,
    _ address: UnsafePointer<sockaddr>?,
    _ length: socklen_t
) -> CInt {
    bind(SOCKET(descriptor), address!, length)
}

@inline(__always)
internal func connect(
    _ descriptor: CInt,
    _ address: UnsafePointer<sockaddr>?,
    _ length: socklen_t
) -> CInt {
    connect(SOCKET(descriptor), address!, length)
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
