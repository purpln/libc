#if canImport(Darwin)
@_exported import Darwin

#elseif canImport(Android)
@_exported import Android

#elseif canImport(WASILibc)
@_exported import WASILibc

#elseif canImport(Glibc)
@_exported import Glibc

#elseif canImport(Musl)
@_exported import Musl

#elseif canImport(ucrt)
@_exported import ucrt

#endif
@_exported import LibCExternal
