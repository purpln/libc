#if os(Android)
let PROP_NAME_MAX = 32
let PROP_VALUE_MAX = 92

internal func systemProperty(named name: String) -> String? {
    withUnsafeTemporaryAllocation(of: CChar.self, capacity: Int(PROP_VALUE_MAX)) { buffer in
        let length = __system_property_get(name, buffer.baseAddress!)
        if length > 0 {
            return String(validatingCString: buffer.baseAddress!)
        }
        return nil
    }
}
#endif
