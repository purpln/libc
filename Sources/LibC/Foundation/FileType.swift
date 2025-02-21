public enum FileType: UInt8 {
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
    public init(rawValue: UInt8) {
#if canImport(Darwin.C) || canImport(Musl) || os(Android)
        let value = Int32(rawValue)
#elseif canImport(Glibc)
        let value = Int(rawValue)
#endif
        
        switch value {
        case DT_FIFO:
            self = .fifo
        case DT_CHR:
            self = .character
        case DT_DIR:
            self = .directory
        case DT_BLK:
            self = .block
        case DT_REG:
            self = .regular
        case DT_LNK:
            self = .symlink
        case DT_SOCK:
            self = .socket
#if canImport(Darwin.C)
        case DT_WHT:
            self = .whiteout
#endif
        case DT_UNKNOWN:
            self = .unknown
        default:
            self = .unknown
        }
    }
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
