public struct Errno: Error, RawRepresentable, Sendable {
    public var rawValue: CInt
    
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
    
    public init() {
        self = .current
    }
}

extension Errno: CustomStringConvertible {
    public var description: String {
        guard let pointer = system_strerror(rawValue) else { return "unknown error" }
        return String(cString: pointer)
    }
}

extension Errno: Equatable {
    public static func == (lhs: Errno, rhs: Errno) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension Errno: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

public extension Errno {
    static var current: Errno {
        get { Errno(rawValue: system_errno) }
        set { system_errno = newValue.rawValue }
    }
}

public extension Errno {
    //Operation not permitted
    @inlinable
    static var notPermited: Errno { Errno(rawValue: _EPERM) }
    
    //No such file or directory
    @inlinable
    static var noSuchEntity: Errno { Errno(rawValue: _ENOENT) }
    
    //No such process
    @inlinable
    static var noSuchProcess: Errno { Errno(rawValue: _ESRCH) }
    
    //Interrupted system call
    @inlinable
    static var interrupted: Errno { Errno(rawValue: _EINTR) }
    
    //Input/output error
    @inlinable
    static var inputOutputError: Errno { Errno(rawValue: _EIO) }
    
    //Device not configured
    @inlinable
    static var notConfigured: Errno { Errno(rawValue: _ENXIO) }
    
    //Argument list too long
    @inlinable
    static var argumentListTooLong: Errno { Errno(rawValue: _E2BIG) }
    
    //Exec format error
    @inlinable
    static var executableFormatError: Errno { Errno(rawValue: _ENOEXEC) }
    
    //Bad file descriptor
    @inlinable
    static var badFileDescriptor: Errno { Errno(rawValue: _EBADF) }
    
    //No child processes
    @inlinable
    static var noChild: Errno { Errno(rawValue: _ECHILD) }
    
    //Resource deadlock avoided
    @inlinable
    static var deadlock: Errno { Errno(rawValue: _EDEADLK) }
    
    //Cannot allocate memory
    @inlinable
    static var allocateMemory: Errno { Errno(rawValue: _ENOMEM) }
    
    //Permission denied
    @inlinable
    static var permissionDenied: Errno { Errno(rawValue: _EACCES) }
    
    //Bad address
    @inlinable
    static var badAddress: Errno { Errno(rawValue: _EFAULT) }
#if !os(Windows) && !os(WASI)
    //Block device required
    @inlinable
    static var blockRequired: Errno { Errno(rawValue: _ENOTBLK) }
#endif
    //Resource busy
    @inlinable
    static var busy: Errno { Errno(rawValue: _EBUSY) }
    
    //File exists
    @inlinable
    static var exists: Errno { Errno(rawValue: _EEXIST) }
    
    //Cross-device link
    @inlinable
    static var crossDeviceLink: Errno { Errno(rawValue: _EXDEV) }
    
    //Operation not supported by device
    @inlinable
    static var notSupported: Errno { Errno(rawValue: _ENODEV) }
    
    //Not a directory
    @inlinable
    static var notDirectory: Errno { Errno(rawValue: _ENOTDIR) }
    
    //Is a directory
    @inlinable
    static var isDirectory: Errno { Errno(rawValue: _EISDIR) }
    
    //Invalid argument
    @inlinable
    static var invalidArgument: Errno { Errno(rawValue: _EINVAL) }
    
    //Too many open files in system
    @inlinable
    static var tooManyOpenedSystem: Errno { Errno(rawValue: _ENFILE) }
    
    //Too many open files
    @inlinable
    static var tooManyOpened: Errno { Errno(rawValue: _EMFILE) }
    
    //Inappropriate ioctl for device
    @inlinable
    static var inappropriate: Errno { Errno(rawValue: _ENOTTY) }
    
    //Text file busy
    @inlinable
    static var textFileBusy: Errno { Errno(rawValue: _ETXTBSY) }
    
    //File too large
    @inlinable
    static var tooLarge: Errno { Errno(rawValue: _EFBIG) }
    
    //No space left on device
    @inlinable
    static var noSpace: Errno { Errno(rawValue: _ENOSPC) }
    
    //Illegal seek
    @inlinable
    static var illegalSeek: Errno { Errno(rawValue: _ESPIPE) }
    
    //Read-only file system
    @inlinable
    static var readOnly: Errno { Errno(rawValue: _EROFS) }
    
    //Too many links
    @inlinable
    static var tooManyLinks: Errno { Errno(rawValue: _EMLINK) }
    
    //Broken pipe
    @inlinable
    static var brokenPipe: Errno { Errno(rawValue: _EPIPE) }
    
    //Numerical argument out of domain
    @inlinable
    static var argumentOutOfDomain: Errno { Errno(rawValue: _EDOM) }
    
    //Result too large
    @inlinable
    static var outOfRange: Errno { Errno(rawValue: _ERANGE) }
    
    //Resource temporarily unavailable
    @inlinable
    static var again: Errno { Errno(rawValue: _EAGAIN) }
    
    //Resource temporarily unavailable
    @inlinable
    static var wouldBlock: Errno { Errno(rawValue: _EWOULDBLOCK) }
    
    //Operation now in progress
    @inlinable
    static var inProgress: Errno { Errno(rawValue: _EINPROGRESS) }
    
    //Operation already in progress
    @inlinable
    static var alreadyInProgress: Errno { Errno(rawValue: _EALREADY) }
    
    //Socket operation on non-socket
    @inlinable
    static var notSocket: Errno { Errno(rawValue: _ENOTSOCK) }
    
    //Destination address required
    @inlinable
    static var destinationAddressRequired: Errno { Errno(rawValue: _EDESTADDRREQ) }
    
    //Message too long
    @inlinable
    static var messageTooLong: Errno { Errno(rawValue: _EMSGSIZE) }
    
    //Protocol wrong type for socket
    @inlinable
    static var wrongProtocolType: Errno { Errno(rawValue: _EPROTOTYPE) }
    
    //Protocol not available
    @inlinable
    static var protocolNotAvailable: Errno { Errno(rawValue: _ENOPROTOOPT) }
    
    //Protocol not supported
    @inlinable
    static var protocolNotSupported: Errno { Errno(rawValue: _EPROTONOSUPPORT) }
#if !os(WASI)
    //Socket type not supported
    @inlinable
    static var socketNotSupported: Errno { Errno(rawValue: _ESOCKTNOSUPPORT) }
#endif
    //Operation not supported
    @inlinable
    static var operationNotSupported: Errno { Errno(rawValue: _ENOTSUP) }
#if !os(WASI)
    //Protocol family not supported
    @inlinable
    static var protocolFamilyNotSupported: Errno { Errno(rawValue: _EPFNOSUPPORT) }
#endif
    //Address family not supported by protocol family
    @inlinable
    static var addressFamilyNotSupported: Errno { Errno(rawValue: _EAFNOSUPPORT) }
    
    //Address already in use
    @inlinable
    static var alreadyInUse: Errno { Errno(rawValue: _EADDRINUSE) }
    
    //Can\'t assign requested address
    @inlinable
    static var assignAddress: Errno { Errno(rawValue: _EADDRNOTAVAIL) }
    
    //Network is down
    @inlinable
    static var networkDown: Errno { Errno(rawValue: _ENETDOWN) }
    
    //Network is unreachable
    @inlinable
    static var networkUnreachable: Errno { Errno(rawValue: _ENETUNREACH) }
    
    //Network dropped connection on reset
    @inlinable
    static var networkDroppedConnection: Errno { Errno(rawValue: _ENETRESET) }
    
    //Software caused connection abort
    @inlinable
    static var connectionAbort: Errno { Errno(rawValue: _ECONNABORTED) }
    
    //Connection reset by peer
    @inlinable
    static var connectionReset: Errno { Errno(rawValue: _ECONNRESET) }
    
    //No buffer space available
    @inlinable
    static var noBufferSpace: Errno { Errno(rawValue: _ENOBUFS) }
    
    //Socket is already connected
    @inlinable
    static var alreadyConnected: Errno { Errno(rawValue: _EISCONN) }
    
    //Socket is not connected
    @inlinable
    static var notConnected: Errno { Errno(rawValue: _ENOTCONN) }
#if !os(WASI)
    //Can\'t send after socket shutdown
    @inlinable
    static var socketShutdown: Errno { Errno(rawValue: _ESHUTDOWN) }
    
    //Too many references: can\'t splice
    @inlinable
    static var tooManyReferences: Errno { Errno(rawValue: _ETOOMANYREFS) }
#endif
    //Operation timed out
    @inlinable
    static var timeout: Errno { Errno(rawValue: _ETIMEDOUT) }
    
    //Connection refused
    @inlinable
    static var connectionRefused: Errno { Errno(rawValue: _ECONNREFUSED) }
    
    //Too many levels of symbolic links
    @inlinable
    static var tooManySymbolicLinks: Errno { Errno(rawValue: _ELOOP) }
    
    //File name too long
    @inlinable
    static var nameTooLong: Errno { Errno(rawValue: _ENAMETOOLONG) }
#if !os(WASI)
    //Host is down
    @inlinable
    static var hostDown: Errno { Errno(rawValue: _EHOSTDOWN) }
#endif
    //No route to host
    @inlinable
    static var hostUnreachable: Errno { Errno(rawValue: _EHOSTUNREACH) }
    
    //Directory not empty
    @inlinable
    static var directoryNotEmpty: Errno { Errno(rawValue: _ENOTEMPTY) }
#if os(macOS) || os(iOS)
    //Too many processes
    @inlinable
    static var tooManyProcesses: Errno { Errno(rawValue: _EPROCLIM) }
#endif
#if !os(WASI)
    //Too many users
    @inlinable
    static var tooManyUsers: Errno { Errno(rawValue: _EUSERS) }
#endif
    //Disc quota exceeded
    @inlinable
    static var discQuotaExceeded: Errno { Errno(rawValue: _EDQUOT) }
    
    //Stale NFS file handle
    @inlinable
    static var stale: Errno { Errno(rawValue: _ESTALE) }
#if !os(WASI)
    //Too many levels of remote in path
    @inlinable
    static var tooManyRemote: Errno { Errno(rawValue: _EREMOTE) }
#endif
#if os(macOS) || os(iOS)
    //Program version wrong
    @inlinable
    static var wrongVersion: Errno { Errno(rawValue: _EPROGMISMATCH) }
    
    //Bad procedure for program
    @inlinable
    static var unavailableProcedure: Errno { Errno(rawValue: _EPROCUNAVAIL) }
#endif
    //No locks available
    @inlinable
    static var noLocks: Errno { Errno(rawValue: _ENOLCK) }
    
    //Function not implemented
    @inlinable
    static var notImplemented: Errno { Errno(rawValue: _ENOSYS) }
#if os(macOS) || os(iOS)
    //Inappropriate file type or format
    @inlinable
    static var inappropriateFile: Errno { Errno(rawValue: _EFTYPE) }
    
    //Authentication error
    @inlinable
    static var authentication: Errno { Errno(rawValue: _EAUTH) }
    
    //Need authenticator
    @inlinable
    static var authenticationNeeded: Errno { Errno(rawValue: _ENEEDAUTH) }
#endif
#if os(macOS) || os(iOS)
    //Device power is off
    @inlinable
    static var powerOff: Errno { Errno(rawValue: _EPWROFF) }
    
    //Device error
    @inlinable
    static var device: Errno { Errno(rawValue: _EDEVERR) }
#endif
    //Value too large to be stored in data type
    @inlinable
    static var overflow: Errno { Errno(rawValue: _EOVERFLOW) }
#if os(macOS) || os(iOS)
    //Bad executable (or shared library)
    @inlinable
    static var badExecutable: Errno { Errno(rawValue: _EBADEXEC) }
    
    //Bad CPU type in executable
    @inlinable
    static var badArchitecture: Errno { Errno(rawValue: _EBADARCH) }
    
    //Shared library version mismatch
    @inlinable
    static var libraryVersionMismatch: Errno { Errno(rawValue: _ESHLIBVERS) }
    
    //Malformed Mach-o file
    @inlinable
    static var badMach: Errno { Errno(rawValue: _EBADMACHO) }
#endif
    //Operation canceled
    @inlinable
    static var canceled: Errno { Errno(rawValue: _ECANCELED) }
    
    //Identifier removed
    @inlinable
    static var removedIdentifier: Errno { Errno(rawValue: _EIDRM) }
    
    //No message of desired type
    @inlinable
    static var noMessage: Errno { Errno(rawValue: _ENOMSG) }
    
    //Illegal byte sequence
    @inlinable
    static var illegalSequence: Errno { Errno(rawValue: _EILSEQ) }
#if os(macOS) || os(iOS)
    //Attribute not found
    @inlinable
    static var noAttribute: Errno { Errno(rawValue: _ENOATTR) }
#endif
    //Bad message
    @inlinable
    static var badMessage: Errno { Errno(rawValue: _EBADMSG) }
}
