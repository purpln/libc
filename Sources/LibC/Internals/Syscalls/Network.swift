public func system_unlink(
    _ path: UnsafePointer<CChar>?
) -> CInt {
#if os(Android) || os(Linux)
    var zero = CChar.zero
    return withUnsafePointer(to: &zero) {
        // has a non-nullable pointer
        unlink(path ?? $0)
    }
#else
    unlink(path)
#endif
}

public func system_inet_ntop(
    _ family: CInt,
    _ address: UnsafeRawPointer,
    _ value: UnsafeMutablePointer<CChar>,
    _ length: socklen_t
) -> UnsafePointer<CChar>? {
    inet_ntop(family, address, value, length)
}

#if !os(WASI)
public func system_socket(
    _ family: CInt,
    _ type: CInt,
    _ protocol: CInt
) -> CInt {
    socket(family, type, `protocol`)
}

public func system_getsockopt(
    _ descriptor: CInt,
    _ level: CInt,
    _ name: CInt,
    _ value: UnsafeMutablePointer<CChar>?,
    _ length: UnsafeMutablePointer<socklen_t>
) -> CInt {
    getsockopt(descriptor, level, name, value, length)
}

public func system_setsockopt(
    _ descriptor: CInt,
    _ level: CInt,
    _ name: CInt,
    _ value: UnsafePointer<CChar>?,
    _ length: socklen_t
) -> CInt {
    setsockopt(descriptor, level, name, value, length)
}

@discardableResult
public func system_getsockname(
    _ descriptor: CInt,
    _ name: UnsafeMutablePointer<sockaddr>,
    _ length: UnsafeMutablePointer<socklen_t>
) -> CInt {
    getsockname(descriptor, name, length)
}

@discardableResult
public func system_getpeername(
    _ descriptor: CInt,
    _ name: UnsafeMutablePointer<sockaddr>,
    _ length: UnsafeMutablePointer<socklen_t>
) -> CInt {
    getpeername(descriptor, name, length)
}

// accept
public func system_accept(
    _ descriptor: CInt,
    _ address: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
    accept(descriptor, address, length)
}

// bind
public func system_bind(
    _ descriptor: CInt,
    _ address: UnsafePointer<sockaddr>,
    _ length: socklen_t
) -> CInt {
    bind(descriptor, address, length)
}

// connect
public func system_connect(
    _ descriptor: CInt,
    _ address: UnsafePointer<sockaddr>,
    _ length: socklen_t
) -> CInt {
    connect(descriptor, address, length)
}

// listen
public func system_listen(
    _ descriptor: CInt,
    _ backlog: CInt
) -> CInt {
    listen(descriptor, backlog)
}

// recieve
public func system_recv(
    _ descriptor: CInt,
    _ buffer: UnsafeMutableRawPointer?,
    _ size: Int,
    _ flags: CInt
) -> Int {
    recv(descriptor, buffer, size, flags)
}

public func system_recvfrom(
    _ descriptor: CInt,
    _ buffer: UnsafeMutableRawPointer?,
    _ size: Int,
    _ flags: CInt,
    _ address: UnsafeMutablePointer<sockaddr>?,
    _ length: UnsafeMutablePointer<socklen_t>?
) -> Int {
    recvfrom(descriptor, buffer, size, flags, address, length)
}

// send
public func system_send(
    _ descriptor: CInt,
    _ buffer: UnsafeRawPointer?,
    _ size: Int,
    _ flags: CInt
) -> Int {
#if os(Android)
    var zero = UInt8.zero
    return withUnsafePointer(to: &zero) {
        // has a non-nullable pointer
        send(descriptor, buffer ?? UnsafeRawPointer($0), size, flags)
    }
#else
    send(descriptor, buffer, size, flags)
#endif
}

public func system_sendto(
    _ descriptor: CInt,
    _ buffer: UnsafeRawPointer?,
    _ size: Int,
    _ flags: CInt,
    _ address: UnsafePointer<sockaddr>?,
    _ length: socklen_t
) -> Int {
#if os(Android)
    var zero = UInt8.zero
    return withUnsafePointer(to: &zero) {
        // has a non-nullable pointer
        sendto(descriptor, buffer ?? UnsafeRawPointer($0), size, flags, address, length)
    }
#else
    sendto(descriptor, buffer, size, flags, address, length)
#endif
}
#endif //!os(WASI)
