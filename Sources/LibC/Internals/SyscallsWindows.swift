#if os(Windows)

import ucrt
import WinSDK

fileprivate var _umask: PlatformMode = 0o22

@inline(__always)
func umask(
    _ mode: PlatformMode
) -> PlatformMode {
    let oldMask = _umask
    _umask = mode
    return oldMask
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
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return -1
    }
    
    return _open_osfhandle(intptr_t(bitPattern: hFile), oflag);
}

@inline(__always)
internal func open(
    _ path: UnsafePointer<PlatformChar>, _ oflag: CInt,
    _ mode: PlatformMode
) -> CInt {
    let actualMode = mode & ~_umask
    
    guard let pSD = _createSecurityDescriptor(from: actualMode, for: .file) else {
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
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
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return -1
    }
    
    return _open_osfhandle(intptr_t(bitPattern: hFile), oflag);
}

@inline(__always)
internal func close(_ descriptor: CInt) -> CInt {
    _close(descriptor)
}

@inline(__always)
internal func lseek(
    _ descriptor: CInt, _ offset: Int64, _ whence: CInt
) -> Int64 {
    _lseeki64(descriptor, offset, whence)
}

@inline(__always)
internal func read(
    _ descriptor: CInt, _ buffer: UnsafeMutableRawPointer!, _ size: Int
) -> Int {
    Int(_read(descriptor, buffer, numericCast(size)))
}

@inline(__always)
internal func write(
    _ descriptor: CInt, _ buffer: UnsafeRawPointer!, _ size: Int
) -> Int {
    Int(_write(descriptor, buffer, numericCast(size)))
}

@inline(__always)
internal func lseek(
    _ descriptor: CInt, _ offset: off_t, _ whence: CInt
) -> off_t {
    _lseek(descriptor, offset, whence)
}

@inline(__always)
internal func dup(_ descriptor: CInt) -> CInt {
    _dup(descriptor)
}

@inline(__always)
internal func dup2(_ descriptor1: CInt, _ descriptor2: CInt) -> CInt {
    _dup2(descriptor1, descriptor2)
}

@inline(__always)
internal func pread(
    _ descriptor: CInt, _ buffer: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
    let handle: intptr_t = _get_osfhandle(descriptor)
    if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }
    
    // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
    let hFile: HANDLE = HANDLE(bitPattern: handle)!
    
    var ovlOverlapped: OVERLAPPED = OVERLAPPED()
    ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
    ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)
    
    var nNumberOfBytesRead: DWORD = 0
    if !ReadFile(hFile, buffer, DWORD(nbyte), &nNumberOfBytesRead, &ovlOverlapped) {
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return Int(-1)
    }
    return Int(nNumberOfBytesRead)
}

@inline(__always)
internal func pwrite(
    _ descriptor: CInt, _ buffer: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
    let handle: intptr_t = _get_osfhandle(descriptor)
    if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }
    
    // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
    let hFile: HANDLE = HANDLE(bitPattern: handle)!
    
    var ovlOverlapped: OVERLAPPED = OVERLAPPED()
    ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
    ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)
    
    var nNumberOfBytesWritten: DWORD = 0
    if !WriteFile(hFile, buffer, DWORD(nbyte), &nNumberOfBytesWritten,
                  &ovlOverlapped) {
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return Int(-1)
    }
    return Int(nNumberOfBytesWritten)
}

@inline(__always)
internal func pipe(
    _ descriptors: UnsafeMutablePointer<Int32>, bytesReserved: UInt32 = 4096
) -> CInt {
    return _pipe(descriptors, bytesReserved, _O_BINARY | _O_NOINHERIT);
}

@inline(__always)
internal func ftruncate(_ descriptor: CInt, _ length: off_t) -> CInt {
    let handle: intptr_t = _get_osfhandle(descriptor)
    if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }
    
    // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
    let hFile: HANDLE = HANDLE(bitPattern: handle)!
    let liDesiredLength = LARGE_INTEGER(QuadPart: LONGLONG(length))
    var liCurrentOffset = LARGE_INTEGER(QuadPart: 0)
    
    // Save the current position and restore it when we're done
    if !SetFilePointerEx(hFile, liCurrentOffset, &liCurrentOffset,
                         DWORD(FILE_CURRENT)) {
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return -1
    }
    defer {
        _ = SetFilePointerEx(hFile, liCurrentOffset, nil, DWORD(FILE_BEGIN));
    }
    
    // Truncate (or extend) the file
    if !SetFilePointerEx(hFile, liDesiredLength, nil, DWORD(FILE_BEGIN))
        || !SetEndOfFile(hFile) {
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
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
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
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
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return -1
    }
    
    return 0;
}

@inline(__always)
internal func rmdir(
    _ path: UnsafePointer<PlatformChar>
) -> CInt {
    if !RemoveDirectoryW(path) {
        ucrt._set_errno(_mapWindowsErrorToErrno(GetLastError()))
        return -1
    }
    
    return 0;
}

internal func _mapWindowsErrorToErrno(_ errorCode: DWORD) -> CInt {
    switch CInt(errorCode) {
    case ERROR_SUCCESS:
        return 0
    case ERROR_INVALID_FUNCTION,
        ERROR_INVALID_ACCESS,
        ERROR_INVALID_DATA,
        ERROR_INVALID_PARAMETER,
    ERROR_NEGATIVE_SEEK:
        return EINVAL
    case ERROR_FILE_NOT_FOUND,
        ERROR_PATH_NOT_FOUND,
        ERROR_INVALID_DRIVE,
        ERROR_NO_MORE_FILES,
        ERROR_BAD_NETPATH,
        ERROR_BAD_NET_NAME,
        ERROR_BAD_PATHNAME,
    ERROR_FILENAME_EXCED_RANGE:
        return ENOENT
    case ERROR_TOO_MANY_OPEN_FILES:
        return EMFILE
    case ERROR_ACCESS_DENIED,
        ERROR_CURRENT_DIRECTORY,
        ERROR_LOCK_VIOLATION,
        ERROR_NETWORK_ACCESS_DENIED,
        ERROR_CANNOT_MAKE,
        ERROR_FAIL_I24,
        ERROR_DRIVE_LOCKED,
        ERROR_SEEK_ON_DEVICE,
        ERROR_NOT_LOCKED,
        ERROR_LOCK_FAILED,
        ERROR_WRITE_PROTECT...ERROR_SHARING_BUFFER_EXCEEDED:
        return EACCES
    case ERROR_INVALID_HANDLE,
        ERROR_INVALID_TARGET_HANDLE,
    ERROR_DIRECT_ACCESS_HANDLE:
        return EBADF
    case ERROR_ARENA_TRASHED,
        ERROR_NOT_ENOUGH_MEMORY,
        ERROR_INVALID_BLOCK,
    ERROR_NOT_ENOUGH_QUOTA:
        return ENOMEM
    case ERROR_BAD_ENVIRONMENT:
        return E2BIG
    case ERROR_BAD_FORMAT,
        ERROR_INVALID_STARTING_CODESEG...ERROR_INFLOOP_IN_RELOC_CHAIN:
        return ENOEXEC
    case ERROR_NOT_SAME_DEVICE:
        return EXDEV
    case ERROR_FILE_EXISTS,
    ERROR_ALREADY_EXISTS:
        return EEXIST
    case ERROR_NO_PROC_SLOTS,
        ERROR_MAX_THRDS_REACHED,
    ERROR_NESTING_NOT_ALLOWED:
        return EAGAIN
    case ERROR_BROKEN_PIPE:
        return EPIPE
    case ERROR_DISK_FULL:
        return ENOSPC
    case ERROR_WAIT_NO_CHILDREN,
    ERROR_CHILD_NOT_COMPLETE:
        return ECHILD
    case ERROR_DIR_NOT_EMPTY:
        return ENOTEMPTY
    case ERROR_NO_UNICODE_TRANSLATION:
        return EILSEQ
    default:
        return EINVAL
    }
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
        
        var dwLength = DWORD(0)
        
        if GetTokenInformation(hToken,
                               ticTokenClass,
                               buffer,
                               DWORD(capacity),
                               &dwLength) {
            return UnsafePointer(buffer.assumingMemoryBound(to: T.self))
        }
        
        buffer.deallocate()
        
        capacity = Int(dwLength)
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
                    everyone.assumingMemoryBound(to: .PlatformChar.self)
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
