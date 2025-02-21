@frozen
public struct FilePermissions: OptionSet, Sendable, Hashable, Codable {
    @_alwaysEmitIntoClient
    public let rawValue: PlatformMode
    
    @_alwaysEmitIntoClient
    public init(rawValue: PlatformMode) { self.rawValue = rawValue }
    
    @_alwaysEmitIntoClient
    public static var otherRead: FilePermissions { .init(rawValue: 0o4) }
    
    @_alwaysEmitIntoClient
    public static var otherWrite: FilePermissions { .init(rawValue: 0o2) }
    
    @_alwaysEmitIntoClient
    public static var otherExecute: FilePermissions { .init(rawValue: 0o1) }
    
    @_alwaysEmitIntoClient
    public static var otherReadWrite: FilePermissions { .init(rawValue: 0o6) }
    
    @_alwaysEmitIntoClient
    public static var otherReadExecute: FilePermissions { .init(rawValue: 0o5) }
    
    @_alwaysEmitIntoClient
    public static var otherWriteExecute: FilePermissions { .init(rawValue: 0o3) }
    
    @_alwaysEmitIntoClient
    public static var otherReadWriteExecute: FilePermissions { .init(rawValue: 0o7) }
    
    @_alwaysEmitIntoClient
    public static var groupRead: FilePermissions { .init(rawValue: 0o40) }
    
    @_alwaysEmitIntoClient
    public static var groupWrite: FilePermissions { .init(rawValue: 0o20) }
    
    @_alwaysEmitIntoClient
    public static var groupExecute: FilePermissions { .init(rawValue: 0o10) }
    
    @_alwaysEmitIntoClient
    public static var groupReadWrite: FilePermissions { .init(rawValue: 0o60) }
    
    @_alwaysEmitIntoClient
    public static var groupReadExecute: FilePermissions { .init(rawValue: 0o50) }
    
    @_alwaysEmitIntoClient
    public static var groupWriteExecute: FilePermissions { .init(rawValue: 0o30) }
    
    @_alwaysEmitIntoClient
    public static var groupReadWriteExecute: FilePermissions { .init(rawValue: 0o70) }
    
    @_alwaysEmitIntoClient
    public static var ownerRead: FilePermissions { .init(rawValue: 0o400) }
    
    @_alwaysEmitIntoClient
    public static var ownerWrite: FilePermissions { .init(rawValue: 0o200) }
    
    @_alwaysEmitIntoClient
    public static var ownerExecute: FilePermissions { .init(rawValue: 0o100) }
    
    @_alwaysEmitIntoClient
    public static var ownerReadWrite: FilePermissions { .init(rawValue: 0o600) }
    
    @_alwaysEmitIntoClient
    public static var ownerReadExecute: FilePermissions { .init(rawValue: 0o500) }
    
    @_alwaysEmitIntoClient
    public static var ownerWriteExecute: FilePermissions { .init(rawValue: 0o300) }
    
    @_alwaysEmitIntoClient
    public static var ownerReadWriteExecute: FilePermissions { .init(rawValue: 0o700) }
    
    @_alwaysEmitIntoClient
    public static var setUserID: FilePermissions { .init(rawValue: 0o4000) }
    
    @_alwaysEmitIntoClient
    public static var setGroupID: FilePermissions { .init(rawValue: 0o2000) }
    
    @_alwaysEmitIntoClient
    public static var saveText: FilePermissions { .init(rawValue: 0o1000) }
}

extension FilePermissions: CustomStringConvertible {
    @inline(never)
    public var description: String {
        let descriptions: [(Element, StaticString)] = [
            (.ownerReadWriteExecute, ".ownerReadWriteExecute"),
            (.ownerReadWrite, ".ownerReadWrite"),
            (.ownerReadExecute, ".ownerReadExecute"),
            (.ownerWriteExecute, ".ownerWriteExecute"),
            (.ownerRead, ".ownerRead"),
            (.ownerWrite, ".ownerWrite"),
            (.ownerExecute, ".ownerExecute"),
            (.groupReadWriteExecute, ".groupReadWriteExecute"),
            (.groupReadWrite, ".groupReadWrite"),
            (.groupReadExecute, ".groupReadExecute"),
            (.groupWriteExecute, ".groupWriteExecute"),
            (.groupRead, ".groupRead"),
            (.groupWrite, ".groupWrite"),
            (.groupExecute, ".groupExecute"),
            (.otherReadWriteExecute, ".otherReadWriteExecute"),
            (.otherReadWrite, ".otherReadWrite"),
            (.otherReadExecute, ".otherReadExecute"),
            (.otherWriteExecute, ".otherWriteExecute"),
            (.otherRead, ".otherRead"),
            (.otherWrite, ".otherWrite"),
            (.otherExecute, ".otherExecute"),
            (.setUserID, ".setUserID"),
            (.setGroupID, ".setGroupID"),
            (.saveText, ".saveText")
        ]
        
        return _buildDescription(descriptions)
    }
}
