internal typealias _COffT = off_t

#if os(Windows)
internal var system_errno: CInt {
    get {
        var value: CInt = 0
        _ = ucrt._get_errno(&value)
        return value
    }
    set {
        _ = ucrt._set_errno(newValue)
    }
}
#else
internal var system_errno: CInt {
    get { errno }
    set { errno = newValue }
}
#endif

internal func system_strerror(_ errnum: CInt) -> UnsafeMutablePointer<Int8>! {
    strerror(errnum)
}

internal func system_strlen(_ s: UnsafePointer<CChar>) -> Int {
    strlen(s)
}
internal func system_strlen(_ s: UnsafeMutablePointer<CChar>) -> Int {
    strlen(s)
}

#if os(Windows)
/// The C `mode_t` type.
internal typealias PlatformMode = CInt

/// The platform's preferred character type. On Unix, this is an 8-bit C
/// `char` (which may be signed or unsigned, depending on platform). On
/// Windows, this is `UInt16` (a "wide" character).
internal typealias PlatformChar = UInt16

/// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
/// Windows it is UTF-16. Native strings may contain invalid Unicode,
/// which will be handled by either error-correction or failing, depending
/// on API.
internal typealias PlatformUnicodeEncoding = UTF16
#else
/// The C `mode_t` type.
public typealias PlatformMode = mode_t

/// The platform's preferred character type. On Unix, this is an 8-bit C
/// `char` (which may be signed or unsigned, depending on platform). On
/// Windows, this is `UInt16` (a "wide" character).
public typealias PlatformChar = CChar

/// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
/// Windows it is UTF-16. Native strings may contain invalid Unicode,
/// which will be handled by either error-correction or failing, depending
/// on API.
public typealias PlatformUnicodeEncoding = UTF8
#endif

// strlen for the platform string
internal func system_platform_strlen(_ s: UnsafePointer<PlatformChar>) -> Int {
#if os(Windows)
    return wcslen(s)
#else
    return strlen(s)
#endif
}

// memset for raw buffers
internal func system_memset(
    _ buffer: UnsafeMutableRawBufferPointer,
    to byte: UInt8
) {
    guard buffer.count > 0 else { return }
    memset(buffer.baseAddress!, CInt(byte), buffer.count)
}

// Interop between String and platfrom string
extension String {
    internal func _withPlatformString<Result>(
        _ body: (UnsafePointer<PlatformChar>) throws -> Result
    ) rethrows -> Result {
        // Need to #if because CChar may be signed
#if os(Windows)
        return try withCString(encodedAs: PlatformUnicodeEncoding.self, body)
#else
        return try withCString(body)
#endif
    }
    
    internal init?(_platformString platformString: UnsafePointer<PlatformChar>) {
        // Need to #if because CChar may be signed
#if os(Windows)
        guard let strRes = String.decodeCString(
            platformString,
            as: PlatformUnicodeEncoding.self,
            repairingInvalidCodeUnits: false
        ) else { return nil }
        assert(strRes.repairsMade == false)
        self = strRes.result
        return
        
#else
        self.init(validatingCString: platformString)
#endif
    }
    
    internal init(
        _errorCorrectingPlatformString platformString: UnsafePointer<PlatformChar>
    ) {
        // Need to #if because CChar may be signed
#if os(Windows)
        let strRes = String.decodeCString(
            platformString,
            as: PlatformUnicodeEncoding.self,
            repairingInvalidCodeUnits: true)
        self = strRes!.result
        return
#else
        self.init(cString: platformString)
#endif
    }
}

// TLS
#if os(Windows)
internal typealias PlatformTLSKey = DWORD
#elseif os(WASI) && (swift(<6.1) || !_runtime(_multithreaded))
// Mock TLS storage for single-threaded WASI
internal final class PlatformTLSKey {
    fileprivate init() {}
}
private final class TLSStorage: @unchecked Sendable {
    var storage = [ObjectIdentifier: UnsafeMutableRawPointer]()
}
private let sharedTLSStorage = TLSStorage()

func pthread_setspecific(_ key: PlatformTLSKey, _ p: UnsafeMutableRawPointer?) -> Int {
    sharedTLSStorage.storage[ObjectIdentifier(key)] = p
    return 0
}

func pthread_getspecific(_ key: PlatformTLSKey) -> UnsafeMutableRawPointer? {
    sharedTLSStorage.storage[ObjectIdentifier(key)]
}
#else
internal typealias PlatformTLSKey = pthread_key_t
#endif

internal func makeTLSKey() -> PlatformTLSKey {
#if os(Windows)
    let raw: DWORD = FlsAlloc(nil)
    if raw == FLS_OUT_OF_INDEXES {
        fatalError("Unable to create key")
    }
    return raw
#elseif os(WASI) && (swift(<6.1) || !_runtime(_multithreaded))
    return PlatformTLSKey()
#else
    var raw = pthread_key_t()
    guard 0 == pthread_key_create(&raw, nil) else {
        fatalError("Unable to create key")
    }
    return raw
#endif
}
internal func setTLS(_ key: PlatformTLSKey, _ p: UnsafeMutableRawPointer?) {
#if os(Windows)
    guard FlsSetValue(key, p) else {
        fatalError("Unable to set TLS")
    }
#else
    guard 0 == pthread_setspecific(key, p) else {
        fatalError("Unable to set TLS")
    }
#endif
}
internal func getTLS(_ key: PlatformTLSKey) -> UnsafeMutableRawPointer? {
#if os(Windows)
    return FlsGetValue(key)
#else
    return pthread_getspecific(key)
#endif
}
