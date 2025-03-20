@usableFromInline
internal let absoluteTimeIntervalSince1970: Double = 978307200

@usableFromInline
internal let absoluteTimeIntervalSince1601: Double = 12622780800

@usableFromInline
internal let format: String = "%Y-%m-%d %H:%M:%S %z"

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
#if os(Windows)
        self = timespec(tv_sec: time_t(whole), tv_nsec: CInt(fraction * 1e9))
#else
        self = timespec(tv_sec: time_t(whole), tv_nsec: Int(fraction * 1e9))
#endif
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
#if os(Windows)
        self = timeval(tv_sec: CInt(whole), tv_usec: CInt(fraction * 1e6))
#else
        self = timeval(tv_sec: time_t(whole), tv_usec: suseconds_t(fraction * 1e6))
#endif
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

public extension timespec {
    static func + (lhs: timespec, rhs: Double) -> timespec {
        lhs + timespec(interval: rhs)
    }
    
    static func - (lhs: timespec, rhs: Double) -> timespec {
        lhs - timespec(interval: rhs)
    }
}

public extension timeval {
    static func + (lhs: timeval, rhs: Double) -> timeval {
        lhs + timeval(interval: rhs)
    }
    
    static func - (lhs: timeval, rhs: Double) -> timeval {
        lhs - timeval(interval: rhs)
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
        let s = lhs.tv_sec + rhs.tv_sec + time_t(raw / 1_000_000_000)
        return timespec(tv_sec: s, tv_nsec: ns)
    }
    
    public static func - (lhs: timespec, rhs: timespec) -> timespec {
        let raw = lhs.tv_nsec - rhs.tv_nsec
        
        if raw >= 0 {
            let ns = raw % 1_000_000_000
            let s = lhs.tv_sec - rhs.tv_sec + time_t(raw / 1_000_000_000)
            return timespec(tv_sec: s, tv_nsec: ns)
        } else {
            let ns = 1_000_000_000 - (-raw % 1_000_000_000)
            let s = lhs.tv_sec - rhs.tv_sec - 1 - time_t(-raw / 1_000_000_000)
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
        let seconds = tv_sec
        let tm = localtime(seconds)
        return strftime(format, tm)
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
#if os(Windows)
        let s = CInt(lhs.tv_sec + rhs.tv_sec) + CInt(raw / 1_000_000)
#else
        let s = lhs.tv_sec + rhs.tv_sec + time_t(raw / 1_000_000)
#endif
        return timeval(tv_sec: s, tv_usec: ns)
    }
    
    public static func - (lhs: timeval, rhs: timeval) -> timeval {
        let raw = lhs.tv_usec - rhs.tv_usec
        
        if raw >= 0 {
            let ns = raw % 1_000_000
#if os(Windows)
            let s = lhs.tv_sec - rhs.tv_sec - 1 - (-raw / 1_000_000)
#else
            let s = time_t(lhs.tv_sec - rhs.tv_sec) + time_t(raw / 1_000_000)
#endif
            return timeval(tv_sec: s, tv_usec: ns)
        } else {
            let ns = 1_000_000 - (-raw % 1_000_000)
#if os(Windows)
            let s = lhs.tv_sec - rhs.tv_sec - 1 - (-raw / 1_000_000)
#else
            let s = time_t(lhs.tv_sec - rhs.tv_sec) - 1 - time_t(-raw / 1_000_000)
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
        let seconds = time_t(tv_sec)
        let tm = localtime(seconds)
        return strftime("%Y-%m-%d %H:%M:%S %z", tm)
    }
}

@inlinable
internal func strftime(_ format: String, _ time: tm) -> String {
    let capacity = 64
    let bytes = [UInt8](unsafeUninitializedCapacity: capacity) { buffer, count in
        count = withUnsafePointer(to: time, {
            strftime(buffer.baseAddress!, capacity, format, $0)
        })
    }
    return String(decoding: bytes, as: UTF8.self)
}

#if os(Windows)
@inlinable
internal func localtime(_ source: time_t) -> tm {
    var time = tm()
    _ = withUnsafePointer(to: source, {
        localtime_s(&time, $0)
    })
    return time
}
#else
@inlinable
internal func localtime(_ source: time_t) -> tm {
    var time = tm()
    _ = withUnsafePointer(to: source, {
        localtime_r($0, &time)
    })
    return time
}
#endif
