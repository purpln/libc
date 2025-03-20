#if os(Windows)
@_transparent
public func sqrt<T: FloatingPoint>(_ x: T) -> T {
    return x.squareRoot()
}

@_transparent
public func fma<T: FloatingPoint>(_ x: T, _ y: T, _ z: T) -> T {
    return z.addingProduct(x, y)
}

@_transparent
public func remainder<T: FloatingPoint>(_ x: T, _ y: T) -> T {
    return x.remainder(dividingBy: y)
}

@_transparent
public func fmod<T: FloatingPoint>(_ x: T, _ y: T) -> T {
    return x.truncatingRemainder(dividingBy: y)
}

@_transparent
public func ceil<T: FloatingPoint>(_ x: T) -> T {
    return x.rounded(.up)
}

@_transparent
public func floor<T: FloatingPoint>(_ x: T) -> T {
    return x.rounded(.down)
}

@_transparent
public func round<T: FloatingPoint>(_ x: T) -> T {
    return x.rounded()
}

@_transparent
public func trunc<T: FloatingPoint>(_ x: T) -> T {
    return x.rounded(.towardZero)
}

@_transparent
public func scalbn<T: FloatingPoint>(_ x: T, _ n : Int) -> T {
    return T(sign: .plus, exponent: T.Exponent(n), significand: x)
}

@_transparent
public func modf<T: FloatingPoint>(_ x: T) -> (T, T) {
    // inf/NaN: return canonicalized x, fractional part zero.
    guard x.isFinite else { return (x+0, 0) }
    let integral = trunc(x)
    let fractional = x - integral
    return (integral, fractional)
}

@_transparent
public func frexp<T: BinaryFloatingPoint>(_ x: T) -> (T, Int) {
    guard x.isFinite else { return (x+0, 0) }
    guard x != 0 else { return (x, 0) }
    // The C stdlib `frexp` uses a different notion of significand / exponent
    // than IEEE 754, so we need to adjust them by a factor of two.
    return (x.significand / 2, Int(x.exponent + 1))
}
#endif
