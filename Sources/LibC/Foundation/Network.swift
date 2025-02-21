#if !os(WASI)
private func getaddrinfo(node: String, service: String, hints: addrinfo?) throws -> [String] {
    var result: CInt
    var resolved: UnsafeMutablePointer<addrinfo>?
    if var hints = hints {
        result = getaddrinfo(node, service, &hints, &resolved)
    } else {
        result = getaddrinfo(node, service, nil, &resolved)
    }
    guard result == 0 else {
        throw Errno()
    }
    defer {
        freeaddrinfo(resolved)
    }
    guard let initial = resolved else {
        return []
    }
    let addresses = sequence(first: initial, next: { $0.pointee.ai_next })
    
    var values: [String] = []
    for address in addresses {
        let info = address.pointee
        var buffer = [UInt8](repeating: 0, count: Int(NI_MAXHOST))
        var port = service.withCString { $0 }
#if canImport(Android)
        getnameinfo(info.ai_addr, info.ai_addrlen, &buffer, buffer.count, &port, service.count, NI_NUMERICHOST | NI_NUMERICSERV)
#else
        getnameinfo(info.ai_addr, info.ai_addrlen, &buffer, socklen_t(buffer.count), &port, socklen_t(service.count), NI_NUMERICHOST | NI_NUMERICSERV)
#endif
        let result = String(decoding: buffer, as: UTF8.self)
        values.append(result)
    }
    return values
}

public func getaddrinfo(node: String, service: String, family: CInt?) throws -> [String] {
    var hints = addrinfo()
    if let family = family {
        hints.ai_family = family
        //hints.ai_socktype = SOCK_STREAM
    }
    return try getaddrinfo(node: node, service: service, hints: hints)
}
#endif
