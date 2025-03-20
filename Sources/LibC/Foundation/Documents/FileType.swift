public enum FileType {
    case regular
    case block
    case character
    case fifo
    case directory
    case symlink
    case socket
    case whiteout
    case unknown
}

extension FileType {
#if !os(Windows)
    public init(rawValue: UInt8) {
        switch CInt(rawValue) {
        case _DT_FIFO:
            self = .fifo
        case _DT_CHR:
            self = .character
        case _DT_DIR:
            self = .directory
        case _DT_BLK:
            self = .block
        case _DT_REG:
            self = .regular
        case _DT_LNK:
            self = .symlink
#if !canImport(WASILibc)
        case _DT_SOCK:
            self = .socket
#endif
#if canImport(Darwin.C)
        case _DT_WHT:
            self = .whiteout
#endif
        case _DT_UNKNOWN:
            self = .unknown
        default:
            self = .unknown
        }
    }
#endif
}
extension FileType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .regular:
            return "regular"
        case .block:
            return "block"
        case .character:
            return "character"
        case .fifo:
            return "fifo"
        case .directory:
            return "directory"
        case .symlink:
            return "symlink"
        case .socket:
            return "socket"
        case .whiteout:
            return "whiteout"
        case .unknown:
            return "unknown"
        }
    }
}
