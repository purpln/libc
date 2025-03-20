#if os(Windows)

@inline(__always)
internal func getenv(
    _ name: UnsafePointer<PlatformChar>
) -> UnsafeMutablePointer<PlatformChar>? {
    let length: DWORD = GetEnvironmentVariableW(name, nil, 0)
    guard length > 0 else { return nil }
    
    var buffer = [WCHAR](repeating: 0, count: Int(length))
    GetEnvironmentVariableW(name, &buffer, length)
    return buffer.withUnsafeMutableBufferPointer({ $0.baseAddress! })
}

@inline(__always)
internal func setenv(
    _ name: UnsafePointer<PlatformChar>,
    _ value: UnsafePointer<PlatformChar>,
    _ overwrite: Int32
) -> CInt {
    if overwrite == 0 {
        if GetEnvironmentVariableW(name, nil, 0) == 0 && GetLastError() != ERROR_ENVVAR_NOT_FOUND {
            print("found")
        }
    }
    guard SetEnvironmentVariableW(name, value) else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    return 0
}

@inline(__always)
internal func strerror(_ number: CInt) -> UnsafeMutablePointer<CChar>? {
    var buffer = [CChar](unsafeUninitializedCapacity: 1024) { buffer, length in
        _ = strerror_s(buffer.baseAddress!, buffer.count, number)
        length = strnlen(buffer.baseAddress!, buffer.count)
    }
    return buffer.withUnsafeMutableBufferPointer({ $0.baseAddress! })
}

@inline(__always)
internal func getcwd(
    _ buffer: UnsafeMutablePointer<PlatformChar>?,
    _ size: size_t
) -> UnsafeMutablePointer<PlatformChar>? {
    let length: DWORD = GetCurrentDirectoryW(0, nil)
    guard length > 0 else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return nil
    }
    var buffer = [WCHAR](repeating: 0, count: Int(length))
    GetCurrentDirectoryW(length, &buffer)
    return buffer.withUnsafeMutableBufferPointer({ $0.baseAddress! })
}

@inline(__always)
internal func chdir(
    _ path: UnsafePointer<PlatformChar>
) -> CInt {
    guard SetCurrentDirectoryW(path) else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    return 0
}

@inline(__always)
internal func symlink(
    _ original: UnsafePointer<PlatformChar>,
    _ target: UnsafePointer<PlatformChar>
) -> CInt {
    let attributes = GetFileAttributesW(original)
    guard attributes != INVALID_FILE_ATTRIBUTES else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    let isDirectory = (CInt(attributes) & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY
    let flags = DWORD(isDirectory ? SYMBOLIC_LINK_FLAG_DIRECTORY : 0) | DWORD(SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)
    
    guard CreateSymbolicLinkW(original, target, flags) != 0 else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    return 0
}

fileprivate var _umask: PlatformMode = 0o22

@inline(__always)
internal func umask(
    _ mode: PlatformMode
) -> PlatformMode {
    let oldMask = _umask
    _umask = mode
    return oldMask
}

@inline(__always)
internal func remove(
    _ path: UnsafePointer<PlatformChar>
) -> CInt {
    guard DeleteFileW(path) else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    return 0
}

@inline(__always)
internal func open(
    _ path: UnsafePointer<PlatformChar>, _ oflag: CInt
) -> CInt {
    let decodedFlags = DecodedOpenFlags(oflag)
    
    var saAttrs = SECURITY_ATTRIBUTES(
        nLength: DWORD(MemoryLayout<SECURITY_ATTRIBUTES>.size),
        lpSecurityDescriptor: nil,
        bInheritHandle: decodedFlags.bInheritHandle
    )
    
    let hFile = CreateFileW(path,
                            decodedFlags.dwDesiredAccess,
                            DWORD(FILE_SHARE_DELETE
                                  | FILE_SHARE_READ
                                  | FILE_SHARE_WRITE),
                            &saAttrs,
                            decodedFlags.dwCreationDisposition,
                            decodedFlags.dwFlagsAndAttributes,
                            nil)
    
    if hFile == INVALID_HANDLE_VALUE {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    return ucrt._open_osfhandle(intptr_t(bitPattern: hFile), oflag);
}

@inline(__always)
internal func open(
    _ path: UnsafePointer<PlatformChar>, _ oflag: CInt,
    _ mode: PlatformMode
) -> CInt {
    let actualMode = mode & ~_umask
    
    guard let pSD = _createSecurityDescriptor(from: actualMode, for: .file) else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    defer {
        pSD.deallocate()
    }
    
    let decodedFlags = DecodedOpenFlags(oflag)
    
    var saAttrs = SECURITY_ATTRIBUTES(
        nLength: DWORD(MemoryLayout<SECURITY_ATTRIBUTES>.size),
        lpSecurityDescriptor: pSD,
        bInheritHandle: decodedFlags.bInheritHandle
    )
    
    let hFile = CreateFileW(path,
                            decodedFlags.dwDesiredAccess,
                            DWORD(FILE_SHARE_DELETE
                                  | FILE_SHARE_READ
                                  | FILE_SHARE_WRITE),
                            &saAttrs,
                            decodedFlags.dwCreationDisposition,
                            decodedFlags.dwFlagsAndAttributes,
                            nil)
    
    if hFile == INVALID_HANDLE_VALUE {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    return ucrt._open_osfhandle(intptr_t(bitPattern: hFile), oflag);
}

@inline(__always)
internal func unlink(_ path: UnsafePointer<CChar>?) -> CInt {
    ucrt._unlink(path)
}

@inline(__always)
internal func close(_ descriptor: CInt) -> CInt {
    ucrt._close(descriptor)
}

@inline(__always)
internal func lseek(
    _ descriptor: CInt, _ offset: Int64, _ whence: CInt
) -> Int64 {
    ucrt._lseeki64(descriptor, offset, whence)
}

@inline(__always)
internal func read(
    _ descriptor: CInt, _ buffer: UnsafeMutableRawPointer!, _ size: Int
) -> Int {
    Int(ucrt._read(descriptor, buffer, numericCast(size)))
}

@inline(__always)
internal func write(
    _ descriptor: CInt, _ buffer: UnsafeRawPointer!, _ size: Int
) -> Int {
    Int(ucrt._write(descriptor, buffer, numericCast(size)))
}

@inline(__always)
internal func lseek(
    _ descriptor: CInt, _ offset: off_t, _ whence: CInt
) -> off_t {
    ucrt._lseek(descriptor, offset, whence)
}

@inline(__always)
internal func dup(_ descriptor: CInt) -> CInt {
    ucrt._dup(descriptor)
}

@inline(__always)
internal func dup2(_ descriptor1: CInt, _ descriptor2: CInt) -> CInt {
    ucrt._dup2(descriptor1, descriptor2)
}

@inline(__always)
internal func pread(
    _ descriptor: CInt, _ buffer: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
    let handle: intptr_t = ucrt._get_osfhandle(descriptor)
    if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }
    
    // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
    let hFile: HANDLE = HANDLE(bitPattern: handle)!
    
    var ovlOverlapped: OVERLAPPED = OVERLAPPED()
    ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
    ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)
    
    var nNumberOfBytesRead: DWORD = 0
    if !ReadFile(hFile, buffer, DWORD(nbyte), &nNumberOfBytesRead, &ovlOverlapped) {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return Int(-1)
    }
    return Int(nNumberOfBytesRead)
}

@inline(__always)
internal func pwrite(
    _ descriptor: CInt, _ buffer: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
    let handle: intptr_t = ucrt._get_osfhandle(descriptor)
    if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }
    
    // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
    let hFile: HANDLE = HANDLE(bitPattern: handle)!
    
    var ovlOverlapped: OVERLAPPED = OVERLAPPED()
    ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
    ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)
    
    var nNumberOfBytesWritten: DWORD = 0
    if !WriteFile(hFile, buffer, DWORD(nbyte), &nNumberOfBytesWritten,
                  &ovlOverlapped) {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return Int(-1)
    }
    return Int(nNumberOfBytesWritten)
}

@inline(__always)
internal func pipe(
    _ descriptors: UnsafeMutablePointer<CInt>, bytesReserved: UInt32 = 4096
) -> CInt {
    return ucrt._pipe(descriptors, bytesReserved, _O_BINARY | _O_NOINHERIT);
}

@inline(__always)
internal func ftruncate(_ descriptor: CInt, _ length: off_t) -> CInt {
    let handle: intptr_t = ucrt._get_osfhandle(descriptor)
    if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }
    
    // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
    let hFile: HANDLE = HANDLE(bitPattern: handle)!
    let liDesiredLength = LARGE_INTEGER(QuadPart: LONGLONG(length))
    var liCurrentOffset = LARGE_INTEGER(QuadPart: 0)
    
    // Save the current position and restore it when we're done
    if !SetFilePointerEx(hFile, liCurrentOffset, &liCurrentOffset,
                         DWORD(FILE_CURRENT)) {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    defer {
        _ = SetFilePointerEx(hFile, liCurrentOffset, nil, DWORD(FILE_BEGIN));
    }
    
    // Truncate (or extend) the file
    if !SetFilePointerEx(hFile, liDesiredLength, nil, DWORD(FILE_BEGIN))
        || !SetEndOfFile(hFile) {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    return 0;
}

@inline(__always)
internal func mkdir(
    _ path: UnsafePointer<PlatformChar>,
    _ mode: PlatformMode
) -> CInt {
    let actualMode = mode & ~_umask
    
    guard let pSD = _createSecurityDescriptor(from: actualMode,
                                              for: .directory) else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    defer {
        pSD.deallocate()
    }
    
    var saAttrs = SECURITY_ATTRIBUTES(
        nLength: DWORD(MemoryLayout<SECURITY_ATTRIBUTES>.size),
        lpSecurityDescriptor: pSD,
        bInheritHandle: false
    )
    
    if !CreateDirectoryW(path, &saAttrs) {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    return 0;
}

@inline(__always)
internal func rmdir(
    _ path: UnsafePointer<PlatformChar>
) -> CInt {
    guard RemoveDirectoryW(path) else {
        ucrt._set_errno(Win32Error().errno.rawValue)
        return -1
    }
    
    return 0;
}

fileprivate func rightsFromModeBits(
    _ bits: Int,
    sticky: Bool = false,
    for fileOrDirectory: _FileOrDirectory
) -> DWORD {
    var rights: DWORD = 0
    
    if (bits & 0o4) != 0 {
        rights |= DWORD(FILE_READ_ATTRIBUTES
                        | FILE_READ_DATA
                        | FILE_READ_EA
                        | STANDARD_RIGHTS_READ
                        | SYNCHRONIZE)
    }
    if (bits & 0o2) != 0 {
        rights |= DWORD(FILE_APPEND_DATA
                        | FILE_WRITE_ATTRIBUTES
                        | FILE_WRITE_DATA
                        | FILE_WRITE_EA
                        | STANDARD_RIGHTS_WRITE
                        | SYNCHRONIZE)
        if fileOrDirectory == .directory && !sticky {
            rights |= DWORD(FILE_DELETE_CHILD)
        }
    }
    if (bits & 0o1) != 0 {
        rights |= DWORD(FILE_EXECUTE
                        | FILE_READ_ATTRIBUTES
                        | STANDARD_RIGHTS_EXECUTE
                        | SYNCHRONIZE)
    }
    
    return rights
}

fileprivate func getTokenInformation<T>(
    of: T.Type,
    hToken: HANDLE,
    ticTokenClass: TOKEN_INFORMATION_CLASS
) -> UnsafePointer<T>? {
    var capacity = 1024
    for _ in 0..<2 {
        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: capacity,
            alignment: MemoryLayout<T>.alignment
        )
        
        var length = DWORD(0)
        
        if GetTokenInformation(hToken,
                               ticTokenClass,
                               buffer,
                               DWORD(capacity),
                               &length) {
            return UnsafePointer(buffer.assumingMemoryBound(to: T.self))
        }
        
        buffer.deallocate()
        
        capacity = Int(length)
    }
    return nil
}

internal enum _FileOrDirectory {
    case file
    case directory
}

/// Build a SECURITY_DESCRIPTOR from UNIX-style "mode" bits.  This only
/// takes account of the rwx and sticky bits; there's really nothing that
/// we can do about setuid/setgid.
internal func _createSecurityDescriptor(from mode: PlatformMode,
                                        for fileOrDirectory: _FileOrDirectory)
-> PSECURITY_DESCRIPTOR? {
    let ownerPerm = (Int(mode) >> 6) & 0o7
    let groupPerm = (Int(mode) >> 3) & 0o7
    let otherPerm = Int(mode) & 0o7
    
    let ownerRights = rightsFromModeBits(ownerPerm, for: fileOrDirectory)
    let groupRights = rightsFromModeBits(groupPerm,
                                         sticky: (mode & 0o1000) != 0,
                                         for: fileOrDirectory)
    let otherRights = rightsFromModeBits(otherPerm,
                                         sticky: (mode & 0o1000) != 0,
                                         for: fileOrDirectory)
    
    // If group or other permissions are *more* permissive, then we need
    // some DENY ACEs as well to implement the expected semantics
    let ownerDenyRights = ((ownerRights ^ groupRights) & groupRights) |
    ((ownerRights ^ otherRights) & otherRights)
    let groupDenyRights = (groupRights ^ otherRights) & otherRights
    
    var SIDAuthWorld = SID_IDENTIFIER_AUTHORITY(Value: (0, 0, 0, 0, 0, 1))
    var everyone: PSID? = nil
    
    guard AllocateAndInitializeSid(&SIDAuthWorld, 1,
                                   DWORD(SECURITY_WORLD_RID),
                                   0, 0, 0, 0, 0, 0, 0,
                                   &everyone) else {
        return nil
    }
    guard let everyone = everyone else {
        return nil
    }
    defer {
        FreeSid(everyone)
    }
    
    let hToken = GetCurrentThreadEffectiveToken()!
    
    guard let pTokenUser = getTokenInformation(of: TOKEN_USER.self,
                                               hToken: hToken,
                                               ticTokenClass: TokenUser) else {
        return nil
    }
    defer {
        pTokenUser.deallocate()
    }
    
    guard let pTokenPrimaryGroup = getTokenInformation(
        of: TOKEN_PRIMARY_GROUP.self,
        hToken: hToken,
        ticTokenClass: TokenPrimaryGroup
    ) else {
        return nil
    }
    defer {
        pTokenPrimaryGroup.deallocate()
    }
    
    let user = pTokenUser.pointee.User.Sid!
    let group = pTokenPrimaryGroup.pointee.PrimaryGroup!
    
    var eas = [
        EXPLICIT_ACCESS_W(
            grfAccessPermissions: ownerRights,
            grfAccessMode: GRANT_ACCESS,
            grfInheritance: DWORD(NO_INHERITANCE),
            Trustee: TRUSTEE_W(
                pMultipleTrustee: nil,
                MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
                TrusteeForm: TRUSTEE_IS_SID,
                TrusteeType: TRUSTEE_IS_USER,
                ptstrName:
                    user.assumingMemoryBound(to: PlatformChar.self)
            )
        ),
        EXPLICIT_ACCESS_W(
            grfAccessPermissions: groupRights,
            grfAccessMode: GRANT_ACCESS,
            grfInheritance: DWORD(NO_INHERITANCE),
            Trustee: TRUSTEE_W(
                pMultipleTrustee: nil,
                MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
                TrusteeForm: TRUSTEE_IS_SID,
                TrusteeType: TRUSTEE_IS_GROUP,
                ptstrName:
                    group.assumingMemoryBound(to: PlatformChar.self)
            )
        ),
        EXPLICIT_ACCESS_W(
            grfAccessPermissions: otherRights,
            grfAccessMode: GRANT_ACCESS,
            grfInheritance: DWORD(NO_INHERITANCE),
            Trustee: TRUSTEE_W(
                pMultipleTrustee: nil,
                MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
                TrusteeForm: TRUSTEE_IS_SID,
                TrusteeType: TRUSTEE_IS_GROUP,
                ptstrName:
                    everyone.assumingMemoryBound(to: PlatformChar.self)
            )
        )
    ]
    
    if ownerDenyRights != 0 {
        eas.append(
            EXPLICIT_ACCESS_W(
                grfAccessPermissions: ownerDenyRights,
                grfAccessMode: DENY_ACCESS,
                grfInheritance: DWORD(NO_INHERITANCE),
                Trustee: TRUSTEE_W(
                    pMultipleTrustee: nil,
                    MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
                    TrusteeForm: TRUSTEE_IS_SID,
                    TrusteeType: TRUSTEE_IS_USER,
                    ptstrName:
                        user.assumingMemoryBound(to: PlatformChar.self)
                )
            )
        )
    }
    
    if groupDenyRights != 0 {
        eas.append(
            EXPLICIT_ACCESS_W(
                grfAccessPermissions: groupDenyRights,
                grfAccessMode: DENY_ACCESS,
                grfInheritance: DWORD(NO_INHERITANCE),
                Trustee: TRUSTEE_W(
                    pMultipleTrustee: nil,
                    MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
                    TrusteeForm: TRUSTEE_IS_SID,
                    TrusteeType: TRUSTEE_IS_GROUP,
                    ptstrName:
                        group.assumingMemoryBound(to: PlatformChar.self)
                )
            )
        )
    }
    
    var pACL: PACL? = nil
    guard SetEntriesInAclW(ULONG(eas.count),
                           &eas,
                           nil,
                           &pACL) == ERROR_SUCCESS else {
        return nil
    }
    defer {
        LocalFree(pACL)
    }
    
    // Create the security descriptor, making sure that inherited ACEs don't
    // take effect, since that wouldn't match the behaviour of mode bits.
    var descriptor = SECURITY_DESCRIPTOR()
    
    guard InitializeSecurityDescriptor(&descriptor,
                                       DWORD(SECURITY_DESCRIPTOR_REVISION)) else {
        return nil
    }
    
    guard SetSecurityDescriptorControl(&descriptor,
                                       SECURITY_DESCRIPTOR_CONTROL(SE_DACL_PROTECTED),
                                       SECURITY_DESCRIPTOR_CONTROL(SE_DACL_PROTECTED))
            && SetSecurityDescriptorOwner(&descriptor, user, false)
            && SetSecurityDescriptorGroup(&descriptor, group, false)
            && SetSecurityDescriptorDacl(&descriptor,
                                         true,
                                         pACL,
                                         false) else {
        return nil
    }
    
    // Make it self-contained (up to this point it uses pointers)
    var dwRelativeSize = DWORD(0)
    
    guard !MakeSelfRelativeSD(&descriptor, nil, &dwRelativeSize)
            && GetLastError() == ERROR_INSUFFICIENT_BUFFER else {
        return nil
    }
    
    let pDescriptor = UnsafeMutableRawPointer.allocate(
        byteCount: Int(dwRelativeSize),
        alignment: MemoryLayout<SECURITY_DESCRIPTOR>.alignment
    ).assumingMemoryBound(to: SECURITY_DESCRIPTOR.self)
    
    guard MakeSelfRelativeSD(&descriptor, pDescriptor, &dwRelativeSize) else {
        pDescriptor.deallocate()
        return nil
    }
    
    return UnsafeMutableRawPointer(pDescriptor)
}

fileprivate struct DecodedOpenFlags {
    var dwDesiredAccess: DWORD
    var dwCreationDisposition: DWORD
    var bInheritHandle: WindowsBool
    var dwFlagsAndAttributes: DWORD
    
    init(_ oflag: CInt) {
        switch oflag & (_O_CREAT | _O_EXCL | _O_TRUNC) {
        case _O_CREAT | _O_EXCL, _O_CREAT | _O_EXCL | _O_TRUNC:
            dwCreationDisposition = DWORD(CREATE_NEW)
        case _O_CREAT:
            dwCreationDisposition = DWORD(OPEN_ALWAYS)
        case _O_CREAT | _O_TRUNC:
            dwCreationDisposition = DWORD(CREATE_ALWAYS)
        case _O_TRUNC:
            dwCreationDisposition = DWORD(TRUNCATE_EXISTING)
        default:
            dwCreationDisposition = DWORD(OPEN_EXISTING)
        }
        
        // The _O_RDONLY, _O_WRONLY and _O_RDWR flags are non-overlapping
        // on Windows; in particular, _O_RDONLY is zero, which means we can't
        // test for it by AND-ing.
        dwDesiredAccess = 0
        switch (oflag & (_O_RDONLY|_O_WRONLY|_O_RDWR)) {
        case _O_RDONLY:
            dwDesiredAccess |= DWORD(GENERIC_READ)
        case _O_WRONLY:
            dwDesiredAccess |= DWORD(GENERIC_WRITE)
        case _O_RDWR:
            dwDesiredAccess |= DWORD(GENERIC_READ) | DWORD(GENERIC_WRITE)
        default:
            break
        }
        
        bInheritHandle = WindowsBool((oflag & _O_NOINHERIT) == 0)
        
        dwFlagsAndAttributes = 0
        if (oflag & _O_SEQUENTIAL) != 0 {
            dwFlagsAndAttributes |= DWORD(FILE_FLAG_SEQUENTIAL_SCAN)
        }
        if (oflag & _O_RANDOM) != 0 {
            dwFlagsAndAttributes |= DWORD(FILE_FLAG_RANDOM_ACCESS)
        }
        if (oflag & _O_TEMPORARY) != 0 {
            dwFlagsAndAttributes |= DWORD(FILE_FLAG_DELETE_ON_CLOSE)
        }
        
        if (oflag & _O_SHORT_LIVED) != 0 {
            dwFlagsAndAttributes |= DWORD(FILE_ATTRIBUTE_TEMPORARY)
        } else {
            dwFlagsAndAttributes |= DWORD(FILE_ATTRIBUTE_NORMAL)
        }
    }
}

#endif
