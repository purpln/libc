public func getCurrentDirectory() throws(Errno) -> String {
    guard let path = system_getcwd(nil, 0) else {
        throw Errno.current
    }
    defer {
        system_free(path)
    }
    return String(cString: path)
}

public func setCurrentDirectory(_ path: String) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        chdir(path)
    }).get()
}

public func getHomeDirectory(for user: String?) -> String? {
#if os(WASI)
    // WASI does not have user concept
    return nil
#else
    let id: UnsafeMutablePointer<passwd>?
    if let user = user {
        id = getpwnam(user)
    } else {
        id = getpwuid(getuid())
    }
    guard let id = id, let pointer = id.pointee.pw_dir else {
        return nil
    }
    return String(cString: pointer)
#endif
}

public func getHomeDirectory() -> String? {
#if os(macOS) || os(iOS)
    guard let value = getenv("HOME") else { return nil }
    return String(cString: value)
#elseif os(WASI)
    // WASI does not have user concept
    return nil
#else
    guard let id: UnsafeMutablePointer<passwd> = getpwuid(getuid()),
          let pointer = id.pointee.pw_dir else { return nil }
    return String(cString: pointer)
#endif
}

public func getDocumentsDirectory() -> String? {
#if os(WASI)
    return nil
#else
    return getHomeDirectory().map({ $0 + "/Documents" })
#endif
}

public func getExecutablePath() -> String {
#if os(macOS) || os(iOS)
    var result: String?
#if DEBUG
    var capacity = UInt32(1) // force looping
#else
    var capacity = UInt32(PATH_MAX)
#endif
    while result == nil {
        withUnsafeTemporaryAllocation(of: CChar.self, capacity: Int(capacity)) { buffer in
            // _NSGetExecutablePath returns 0 on success and -1 if bufferCount is
            // too small. If that occurs, we'll return nil here and loop with the
            // new value of bufferCount.
            if 0 == _NSGetExecutablePath(buffer.baseAddress, &capacity) {
                result = String(cString: buffer.baseAddress!)
            }
        }
    }
    return result!
#elseif os(Linux) || os(Android)
    let capacity = Int(PATH_MAX)
    let buffer = [UInt8](unsafeUninitializedCapacity: capacity) { buffer, count in
        count = readlink("/proc/self/exe", buffer.baseAddress!, capacity)
    }
    return String(decoding: buffer, as: UTF8.self)
#elseif os(WASI)
    return CommandLine.arguments.first ?? "/"
#else
    var buffer = [WCHAR](repeating: 0, count: Int(MAX_PATH))
    let result = GetModuleFileNameW(nil, &buffer, DWORD(buffer.count))
    guard result == 0 else { return "/" }
    return String(decodingCString: buffer, as: UTF16.self)
#endif
}

public func getDirectoryContents(_ path: String) throws(Errno) -> [(name: String, type: FileType)] {
    let allocator = Allocator(open: { () throws(Errno) in
        guard let pointer = system_opendir(path) else { throw Errno.current }
        return pointer
    }, close: { pointer throws(Errno) in
        try nothingOrErrno(retryOnInterrupt: false, {
            system_closedir(pointer)
        }).get()
    })
    let pointer = try allocator.allocate()
    
    var results = [(name: String, type: FileType)]()
    while let entity = system_readdir(pointer) {
        guard entity.pointee.d_ino != 0 else { continue }
#if !os(WASI)
        var name = entity.pointee.d_name
        let path = withUnsafePointer(to: &name) { pointer -> String in
            let buffer = pointer.withMemoryRebound(to: UInt8.self, capacity: Int(entity.pointee.d_reclen)) { pointer  in
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
                [UInt8](UnsafeBufferPointer(start: pointer, count: Int(entity.pointee.d_namlen)))
#elseif os(Linux) || os(Android)
                [UInt8](UnsafeBufferPointer(start: pointer, count: strlen(pointer)))
#endif
            }
            return String(decoding: buffer, as: UTF8.self)
        }
#elseif os(WASI)
        let path = String(cString: _platform_shims_dirent_d_name(entity))
#endif
        let type = entity.pointee.d_type
        results.append((path, FileType(rawValue: type)))
    }
    return results.filter({ !($0.name == "." || $0.name == "..") })
}

public func exists(path: String) -> Bool {
    var s = stat()
    if lstat(path, &s) >= 0 {
#if os(Android) && _pointerBitWidth(_32)
        if (UInt16(s.st_mode) & S_IFMT) == S_IFLNK {
            if (UInt16(s.st_mode) & S_ISVTX) == S_ISVTX {
                return true
            }
            stat(path, &s)
        }
#else
        // don't chase the link for this magic case -- we might be /Net/foo
        // which is a symlink to /private/Net/foo which is not yet mounted...
        if (s.st_mode & S_IFMT) == S_IFLNK {
            if (s.st_mode & S_ISVTX) == S_ISVTX {
                return true
            }
            // chase the link; too bad if it is a slink to /Net/foo
            stat(path, &s)
        }
#endif
    } else {
        return false
    }
    return true
}

public func createDirectory(_ path: String) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        system_mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO)
    }).get()
}

public func removeDirectory(_ path: String) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        system_rmdir(path)
    }).get()
}
