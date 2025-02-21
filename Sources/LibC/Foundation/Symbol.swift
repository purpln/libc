/// The platform-specific type of a loaded image handle.
#if os(macOS) || os(iOS) || os(Linux) || os(Android)
public typealias ImageAddress = UnsafeMutableRawPointer
#elseif os(Windows)
public typealias ImageAddress = HMODULE
#elseif os(WASI)
public typealias ImageAddress = Never
#else
#warning("Platform-specific implementation missing: Dynamic loading unavailable")
public typealias ImageAddress = Never
#endif

/// The value of `RTLD_DEFAULT` on this platform.
///
/// This value is provided because `errno` is a complex macro on some platforms
/// and cannot be imported directly into Swift. As well, `RTLD_DEFAULT` is only
/// defined on Linux when `_GNU_SOURCE` is defined, so it is not sufficient to
/// declare a wrapper function in the internal module's Stubs.h file.
#if os(macOS) || os(iOS)
private nonisolated(unsafe) let RTLD_DEFAULT = ImageAddress(bitPattern: -2)
#elseif os(Android) && _pointerBitWidth(_32)
private nonisolated(unsafe) let RTLD_DEFAULT = ImageAddress(bitPattern: 0xFFFFFFFF as UInt)
#elseif os(Linux) || os(Android)
private nonisolated(unsafe) let RTLD_DEFAULT = ImageAddress(bitPattern: 0)
#endif

/// Use the platform's dynamic loader to get a symbol in the current process
/// at runtime.
///
/// - Parameters:
///   - handle: A platform-specific handle to the image in which to look for
///     `symbolName`. If `nil`, the symbol may be found in any image loaded
///     into the current process.
///   - symbolName: The name of the symbol to find.
///
/// - Returns: A pointer to the specified symbol, or `nil` if it could not be
///   found.
///
/// Callers looking for a symbol declared in a specific image should pass a
/// handle acquired from `dlopen()` as the `handle` argument. On Windows, pass
/// the result of `GetModuleHandleW()` or an equivalent function.
///
/// On Apple platforms and Linux, when `handle` is `nil`, this function is
/// equivalent to `dlsym(RTLD_DEFAULT, symbolName)`.
///
/// On Windows, there is no equivalent of `RTLD_DEFAULT`. It is simulated by
/// calling `EnumProcessModules()` and iterating over the returned handles
/// looking for one containing the given function.
public func symbol(in handle: ImageAddress? = nil, named symbolName: String) -> UnsafeRawPointer? {
#if os(macOS) || os(iOS) || os(Linux) || os(Android)
    dlsym(handle ?? RTLD_DEFAULT, symbolName).map(UnsafeRawPointer.init)
#elseif os(Windows)
    symbolName.withCString { symbolName in
        // If the caller supplied a module, use it.
        if let handle {
            return GetProcAddress(handle, symbolName).map {
                unsafeBitCast($0, to: UnsafeRawPointer.self)
            }
        }
        
        return HMODULE.all.lazy
            .compactMap { GetProcAddress($0, symbolName) }
            .map { unsafeBitCast($0, to: UnsafeRawPointer.self) }
            .first
    }
#elseif os(WASI)
    return nil
#else
#warning("Platform-specific implementation missing: Dynamic loading unavailable")
    return nil
#endif
}
/*
 let test = symbol(named: "test").map({
     unsafeBitCast($0, to: (@convention(c) () -> Void).self)
 })
 test?()
 
 @_cdecl("test")
 func test() {
     print("test")
 }
 */
