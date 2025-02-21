extension String {
    @_disfavoredOverload
    public init(platformString: UnsafePointer<PlatformChar>) {
        self.init(_errorCorrectingPlatformString: platformString)
    }
    
    @inlinable
    @_alwaysEmitIntoClient
    public init(platformString: [PlatformChar]) {
        guard let _ = platformString.firstIndex(of: 0) else {
            fatalError(
                "input of String.init(platformString:) must be null-terminated"
            )
        }
        self = platformString.withUnsafeBufferPointer {
            String(platformString: $0.baseAddress!)
        }
    }
    
    @inlinable
    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use String.init(_ scalar: Unicode.Scalar)")
    public init(platformString: inout PlatformChar) {
        guard platformString == 0 else {
            fatalError(
                "input of String.init(platformString:) must be null-terminated"
            )
        }
        self = ""
    }
    
    @inlinable
    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use a copy of the String argument")
    public init(platformString: String) {
        if let nullLoc = platformString.firstIndex(of: "\0") {
            self = String(platformString[..<nullLoc])
        } else {
            self = platformString
        }
    }
    
    public init?(
        validatingPlatformString platformString: UnsafePointer<PlatformChar>
    ) {
        self.init(_platformString: platformString)
    }
    
    @inlinable
    @_alwaysEmitIntoClient
    public init?(
        validatingPlatformString platformString: [PlatformChar]
    ) {
        guard let _ = platformString.firstIndex(of: 0) else {
            fatalError(
                "input of String.init(validatingPlatformString:) must be null-terminated"
            )
        }
        guard let string = platformString.withUnsafeBufferPointer({
            String(validatingPlatformString: $0.baseAddress!)
        }) else {
            return nil
        }
        self = string
    }
    
    @inlinable
    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use String(_ scalar: Unicode.Scalar)")
    public init?(
        validatingPlatformString platformString: inout PlatformChar
    ) {
        guard platformString == 0 else {
            fatalError(
                "input of String.init(validatingPlatformString:) must be null-terminated"
            )
        }
        self = ""
    }
    
    @inlinable
    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use a copy of the String argument")
    public init?(
        validatingPlatformString platformString: String
    ) {
        if let nullLoc = platformString.firstIndex(of: "\0") {
            self = String(platformString[..<nullLoc])
        } else {
            self = platformString
        }
    }
    
    public func withPlatformString<Result>(
        _ body: (UnsafePointer<PlatformChar>) throws -> Result
    ) rethrows -> Result {
        try _withPlatformString(body)
    }
    
}

extension PlatformChar {
    internal var _platformCodeUnit: PlatformUnicodeEncoding.CodeUnit {
#if os(Windows)
        return self
#else
        return PlatformUnicodeEncoding.CodeUnit(bitPattern: self)
#endif
    }
}

extension PlatformUnicodeEncoding.CodeUnit {
    internal var _platformChar: PlatformChar {
#if os(Windows)
        return self
#else
        return PlatformChar(bitPattern: self)
#endif
    }
}

internal protocol _PlatformStringable {
    func _withPlatformString<Result>(
        _ body: (UnsafePointer<PlatformChar>) throws -> Result
    ) rethrows -> Result
    
    init?(_platformString: UnsafePointer<PlatformChar>)
}
extension String: _PlatformStringable {}
