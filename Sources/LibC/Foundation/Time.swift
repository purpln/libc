@usableFromInline
internal let absoluteTimeIntervalSince1970: Double = 978307200

public extension timespec {
    @inlinable
    static var now: timespec {
        var timespec = timespec()
        clock_gettime(_CLOCK_REALTIME, &timespec)
        return timespec
    }
    
    @inlinable
    static var absolute: Double {
        now.interval - absoluteTimeIntervalSince1970
    }
}

public extension timespec {
    @inlinable
    init<T: BinaryFloatingPoint>(interval: T) {
        let (whole, fraction) = modf(interval)
        self = timespec(tv_sec: time_t(whole), tv_nsec: Int(fraction * 1e9))
    }
    
    @inlinable
    var interval: Double {
        let (seconds, nanoseconds) = components
        return (seconds) + (nanoseconds * 1e-9)
    }
    
    @inlinable
    var components: (seconds: Double, nanoseconds: Double) {
        (Double(tv_sec), Double(tv_nsec))
    }
}

public extension timeval {
    @inlinable
    static var now: timeval {
        var timeval = timeval()
        gettimeofday(&timeval, nil)
        return timeval
    }
    
    @inlinable
    static var absolute: Double {
        now.interval - absoluteTimeIntervalSince1970
    }
}

public extension timeval {
    @inlinable
    init<T: BinaryFloatingPoint>(interval: T) {
        let (whole, fraction) = modf(interval)
        self = timeval(tv_sec: time_t(whole), tv_usec: suseconds_t(fraction * 1e6))
    }
    
    @inlinable
    var interval: Double {
        let (seconds, microseconds) = components
        return (seconds) + (microseconds * 1e-6)
    }
    
    @inlinable
    var components: (seconds: Double, microseconds: Double) {
        (Double(tv_sec), Double(tv_usec))
    }
}

#if hasFeature(RetroactiveAttribute)
extension timespec: @retroactive Equatable {}
extension timespec: @retroactive Comparable {}
extension timespec: @retroactive Hashable {}
extension timespec: @retroactive AdditiveArithmetic {}
extension timespec: @retroactive CustomStringConvertible {}
#else
extension timespec: Equatable {}
extension timespec: Comparable {}
extension timespec: Hashable {}
extension timespec: AdditiveArithmetic {}
extension timespec: CustomStringConvertible {}
#endif

extension timespec /* Equatable */ {
    public static func == (lhs: timespec, rhs: timespec) -> Bool {
        lhs.tv_sec == rhs.tv_sec && lhs.tv_nsec == rhs.tv_nsec
    }
}

extension timespec /* Comparable */ {
    public static func < (lhs: timespec, rhs: timespec) -> Bool {
        if lhs.tv_sec < rhs.tv_sec { return true }
        if lhs.tv_sec > rhs.tv_sec { return false }
        
        if lhs.tv_nsec < rhs.tv_nsec { return true }
        
        return false
    }
}

extension timespec /* Hashable */ {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tv_sec)
        hasher.combine(tv_nsec)
    }
}

extension timespec /* AdditiveArithmetic */ {
    public static func + (lhs: timespec, rhs: timespec) -> timespec {
        let raw = rhs.tv_nsec + lhs.tv_nsec
        let ns = raw % 1_000_000_000
#if os(WASI)
        let s = lhs.tv_sec + rhs.tv_sec + Int64(raw / 1_000_000_000)
#else
        let s = lhs.tv_sec + rhs.tv_sec + (raw / 1_000_000_000)
#endif
        return timespec(tv_sec: s, tv_nsec: ns)
    }
    
    public static func - (lhs: timespec, rhs: timespec) -> timespec {
        let raw = lhs.tv_nsec - rhs.tv_nsec
        
        if raw >= 0 {
            let ns = raw % 1_000_000_000
#if os(WASI)
            let s = lhs.tv_sec - rhs.tv_sec + Int64(raw / 1_000_000_000)
#else
            let s = lhs.tv_sec - rhs.tv_sec + (raw / 1_000_000_000)
#endif
            return timespec(tv_sec: s, tv_nsec: ns)
        } else {
            let ns = 1_000_000_000 - (-raw % 1_000_000_000)
#if os(WASI)
            let s = lhs.tv_sec - rhs.tv_sec - 1 - Int64(-raw / 1_000_000_000)
#else
            let s = lhs.tv_sec - rhs.tv_sec - 1 - (-raw / 1_000_000_000)
#endif
            return timespec(tv_sec: s, tv_nsec: ns)
        }
    }
    
    public static var zero: timespec {
        timespec()
    }
}

extension timespec /* CustomStringConvertible */ {
    @inlinable
    public var description: String {
        var seconds = tv_sec
        let ts = localtime(&seconds)
        
        let length = 64
        let buffer = [UInt8](unsafeUninitializedCapacity: length) { buffer, count in
            count = strftime(buffer.baseAddress!, length, /* %A */ "%Y-%m-%d %H:%M:%S %z", ts!)
        }
        return String(decoding: buffer, as: UTF8.self)
    }
}

#if hasFeature(RetroactiveAttribute)
extension timeval: @retroactive Equatable {}
extension timeval: @retroactive Comparable {}
extension timeval: @retroactive Hashable {}
extension timeval: @retroactive AdditiveArithmetic {}
extension timeval: @retroactive CustomStringConvertible {}
#else
extension timeval: Equatable {}
extension timeval: Comparable {}
extension timeval: Hashable {}
extension timeval: AdditiveArithmetic {}
extension timeval: CustomStringConvertible {}
#endif

extension timeval /* Equatable */ {
    public static func == (lhs: timeval, rhs: timeval) -> Bool {
        lhs.tv_sec == rhs.tv_sec && lhs.tv_usec == rhs.tv_usec
    }
}

extension timeval /* Comparable */ {
    public static func < (lhs: timeval, rhs: timeval) -> Bool {
        if lhs.tv_sec < rhs.tv_sec { return true }
        if lhs.tv_sec > rhs.tv_sec { return false }
        
        if lhs.tv_usec < rhs.tv_usec { return true }
        
        return false
    }
}

extension timeval /* Hashable */ {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tv_sec)
        hasher.combine(tv_usec)
    }
}

extension timeval /* AdditiveArithmetic */ {
    public static func + (lhs: timeval, rhs: timeval) -> timeval {
        let raw = rhs.tv_usec + lhs.tv_usec
        let ns = raw % 1_000_000
#if os(WASI)
        let s = lhs.tv_sec + rhs.tv_sec + (raw / 1_000_000)
#else
        let s = lhs.tv_sec + rhs.tv_sec + (Int(raw) / 1_000_000)
#endif
        return timeval(tv_sec: s, tv_usec: ns)
    }
    
    public static func - (lhs: timeval, rhs: timeval) -> timeval {
        let raw = lhs.tv_usec - rhs.tv_usec
        
        if raw >= 0 {
            let ns = raw % 1_000_000
#if os(WASI)
            let s = lhs.tv_sec - rhs.tv_sec + (raw / 1_000_000)
#else
            let s = lhs.tv_sec - rhs.tv_sec + (Int(raw) / 1_000_000)
#endif
            return timeval(tv_sec: s, tv_usec: ns)
        } else {
            let ns = 1_000_000 - (-raw % 1_000_000)
#if os(WASI)
            let s = lhs.tv_sec - rhs.tv_sec - 1 - (-raw / 1_000_000)
#else
            let s = lhs.tv_sec - rhs.tv_sec - 1 - (-Int(raw) / 1_000_000)
#endif
            return timeval(tv_sec: s, tv_usec: ns)
        }
    }
    
    public static var zero: timeval {
        timeval()
    }
}

extension timeval /* CustomStringConvertible */ {
    @inlinable
    public var description: String {
        var seconds = tv_sec
        let ts = localtime(&seconds)
        
        let length = 64
        let buffer = [UInt8](unsafeUninitializedCapacity: length) { buffer, count in
            count = strftime(buffer.baseAddress!, length, /* %A */ "%Y-%m-%d %H:%M:%S %z", ts!)
        }
        return String(decoding: buffer, as: UTF8.self)
    }
}
