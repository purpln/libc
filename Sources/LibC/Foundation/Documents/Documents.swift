public func getHomeDirectory() -> String? {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    getenv("HOME")
#elseif os(WASI)
    // WASI does not have user concept
    return nil
#elseif os(Windows)
    let name = #"%USERPROFILE%\"#
    let length: DWORD = name.withPlatformString({
        ExpandEnvironmentStringsW($0, nil, 0)
    })
    let bytes = [WCHAR](unsafeUninitializedCapacity: Int(length), initializingWith: { buffer, count in
        let length = name.withPlatformString({
            ExpandEnvironmentStringsW($0, buffer.baseAddress!, length)
        })
        count = Int(length)
    })
    return String(platformString: bytes)
#else
    guard let id: UnsafeMutablePointer<passwd> = getpwuid(getuid()),
          let pointer = id.pointee.pw_dir else { return nil }
    return String(cString: pointer)
#endif
}

public func getDocumentsDirectory() -> String? {
#if os(WASI)
    return nil
#elseif os(Windows)
    return getHomeDirectory().map({ $0 + #"\Documents"# })
#else
    return getHomeDirectory().map({ $0 + "/Documents" })
#endif
}

public func getExecutablePath() throws -> String {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
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
    String(unsafeUninitializedCapacity: Int(PATH_MAX)) { buffer in
        readlink("/proc/self/exe", buffer.baseAddress!, buffer.count)
    }
#elseif os(WASI)
    return CommandLine.arguments.first ?? "/"
#elseif os(Windows)
    var result: String?
#if DEBUG
    var capacity = Int(1) // force looping
#else
    var capacity = Int(MAX_PATH)
#endif
    while result == nil {
        try withUnsafeTemporaryAllocation(of: wchar_t.self, capacity: capacity) { buffer in
            SetLastError(DWORD(ERROR_SUCCESS))
            _ = GetModuleFileNameW(nil, buffer.baseAddress!, DWORD(buffer.count))
            switch GetLastError() {
            case DWORD(ERROR_SUCCESS):
                result = String.decodeCString(buffer.baseAddress!, as: UTF16.self)?.result
                if result == nil {
                    throw Win32Error(rawValue: DWORD(ERROR_ILLEGAL_CHARACTER)).errno
                }
            case DWORD(ERROR_INSUFFICIENT_BUFFER):
                capacity += Int(MAX_PATH)
            case let errorCode:
                throw Win32Error(rawValue: errorCode).errno
            }
        }
    }
    return result!
#endif
}

public typealias Content = (name: String, type: FileType, size: UInt64, create: timespec, modify: timespec, access: timespec)

public func getDirectoryContents(_ path: String) throws(Errno) -> [Content] {
#if !os(Windows)
    let allocator = Allocator(open: { () throws(Errno) in
        guard let pointer = system_opendir(path) else { throw Errno.current }
        return pointer
    }, close: { pointer throws(Errno) in
        try nothingOrErrno(retryOnInterrupt: false, {
            system_closedir(pointer)
        }).get()
    })
    let pointer = try allocator.allocate()
    
    var results = [Content]()
    while let entity = system_readdir(pointer) {
        guard entity.pointee.d_ino != 0 else { continue }
#if !os(WASI)
        let name = withUnsafePointer(to: entity.pointee.d_name) { pointer -> String in
            let buffer = pointer.withMemoryRebound(to: UInt8.self, capacity: Int(entity.pointee.d_reclen)) { pointer  in
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                [UInt8](UnsafeBufferPointer(start: pointer, count: Int(entity.pointee.d_namlen)))
#elseif os(Linux) || os(Android)
                [UInt8](UnsafeBufferPointer(start: pointer, count: strlen(pointer)))
#endif
            }
            return String(decoding: buffer, as: UTF8.self)
        }
#elseif os(WASI)
        let name = String(cString: _platform_shims_dirent_d_name(entity))
#endif
        let info = try system_stat("\(path)/\(name)")
        let type = FileType(rawValue: entity.pointee.d_type)
        let size = UInt64(info.st_size)
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        let create = info.st_birthtimespec
        let modify = info.st_mtimespec
        let access = info.st_atimespec
#else
        let create = info.st_ctim
        let modify = info.st_mtim
        let access = info.st_atim
#endif
        let result: Content = (name, type, size, create, modify, access)
        results.append(result)
    }
    return results.filter({ !($0.name == "." || $0.name == "..") })
#else
    var findData = WIN32_FIND_DATAW()
    let handle = (path + #"\*"#).withPlatformString({
        FindFirstFileW($0, &findData)
    })
    guard handle != INVALID_HANDLE_VALUE else {
        throw Win32Error().errno
    }
    defer {
        FindClose(handle)
    }
    
    var results = [Content]()
    repeat {
        let name: String = withUnsafeBytes(of: findData.cFileName) {
            $0.withMemoryRebound(to: WCHAR.self) {
                String(decodingCString: $0.baseAddress!, as: UTF16.self)
            }
        }
        let type: FileType = (CInt(findData.dwFileAttributes) & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY ? .directory : .regular
        let size = (UInt64(findData.nFileSizeHigh) << 32) | UInt64(findData.nFileSizeLow << 0)
        let create = timespec(tv_sec: time_t(findData.ftCreationTime.seconds), tv_nsec: 0)
        let modify = timespec(tv_sec: time_t(findData.ftLastWriteTime.seconds), tv_nsec: 0)
        let access = timespec(tv_sec: time_t(findData.ftLastAccessTime.seconds), tv_nsec: 0)
        let result: Content = (name, type, size, create, modify, access)
        results.append(result)
    } while FindNextFileW(handle, &findData)
    return results.filter({ !($0.name == "." || $0.name == "..") })
#endif
}

public func exists(path: String) -> Bool {
#if !os(Windows)
    guard let info = try? system_lstat(path) else { return false }
    // don't chase the link for this magic case -- we might be /Net/foo
    // which is a symlink to /private/Net/foo which is not yet mounted...
    guard (mode_t(info.st_mode) & S_IFMT) == S_IFLNK,
          (mode_t(info.st_mode) & S_ISVTX) != S_ISVTX else { return true }
    // chase the link; too bad if it is a slink to /Net/foo
    return (try? system_stat(path)) != nil
#else
    return path.withPlatformString({
        GetFileAttributesW($0) != INVALID_FILE_ATTRIBUTES
    })
#endif
}

public func getCurrentDirectory() throws(Errno) -> String {
    guard let path = system_getcwd(nil, 0) else {
        throw Errno.current
    }
    defer {
        system_free(path)
    }
    return String(platformString: path)
}

public func setCurrentDirectory(_ path: String) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        path.withPlatformString({
            system_chdir($0)
        })
    }).get()
}

public func createDirectory(_ path: String, permissions: FilePermissions) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        path.withPlatformString({
            system_mkdir($0, permissions.rawValue)
        })
    }).get()
}

public func removeDirectory(_ path: String) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        path.withPlatformString({
            system_rmdir($0)
        })
    }).get()
}

public func symbolic(link original: String, _ target: String) throws(Errno) {
    try nothingOrErrno(retryOnInterrupt: false, {
        original.withPlatformString({ original in
            target.withPlatformString({ target in
                system_symlink(original, target)
            })
        })
    }).get()
}

public func remove(path: String) throws {
    try nothingOrErrno(retryOnInterrupt: false, {
        path.withPlatformString({
            system_remove($0)
        })
    }).get()
}

public func read(path: String) throws -> [UInt8] {
    let allocator = Allocator(open: {
        try FileDescriptor.open(path, .readOnly)
    }, close: { descriptor in
        try descriptor.close()
    })
    let pointer = try allocator.allocate()
    
    var result = [UInt8]()
    
    while true {
        let bytes = try [UInt8](unsafeUninitializedCapacity: 4096, initializingWith: { buffer, count in
            count = try pointer.read(into: UnsafeMutableRawBufferPointer(buffer))
        })
        if bytes.isEmpty { break }
        result.append(contentsOf: bytes)
    }
    
    return result
}

public func write(path: String, bytes: [UInt8]) throws {
    let allocator = Allocator(open: {
        try FileDescriptor.open(path, .writeOnly, options: [.create, .truncate], permissions: .ownerReadWriteExecute)
    }, close: { descriptor in
        try descriptor.close()
    })
    let pointer = try allocator.allocate()
    
    let count = bytes.count
    var result = 0
    
    while true {
        result += try bytes.withUnsafeBufferPointer({
            try pointer.write(UnsafeRawBufferPointer($0))
        })
        if result == count { break }
    }
}

public func copy(from origin: String, to destination: String) throws {
    let originAllocator = Allocator(open: {
        try FileDescriptor.open(origin, .readOnly)
    }, close: { descriptor in
        try descriptor.close()
    })
    let destinationAllocator = Allocator(open: {
        try FileDescriptor.open(destination, .writeOnly, options: [.create, .truncate], permissions: .ownerReadWriteExecute)
    }, close: { descriptor in
        try descriptor.close()
    })
    let origin = try originAllocator.allocate()
    let destination = try destinationAllocator.allocate()
    
    var buffer = [UInt8](repeating: 0, count: 4096)
    
    while true {
        let length = try buffer.withUnsafeMutableBytes({ buffer in
            try origin.read(into: buffer)
        })
        guard length > 0 else { break }
        let count = try buffer[0..<length].withUnsafeBytes({ buffer in
            try destination.write(UnsafeRawBufferPointer(buffer))
        })
        guard length == count else {
            preconditionFailure("read: \(length), write: \(count)")
        }
    }
}
