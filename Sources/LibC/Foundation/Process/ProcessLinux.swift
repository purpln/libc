#if os(Linux)
internal func readOSRelease() -> [String:String]? {
    var descriptor: FileDescriptor
    do {
        descriptor = try FileDescriptor.open("/etc/os-release", .readOnly)
    } catch {
        do {
            descriptor = try FileDescriptor.open("/usr/lib/os-release", .readOnly)
        } catch {
            return nil
        }
    }
    defer {
        try? descriptor.close()
    }
    return try? readOSRelease(descriptor: descriptor)
}

private func readOSRelease(descriptor: FileDescriptor) throws -> [String:String]? {
    let contents = try readContents(descriptor: descriptor)
    return Dictionary(OSReleaseScanner(contents), uniquingKeysWith: { $1 })
}

internal struct OSReleaseScanner<S: StringProtocol>: Sequence, IteratorProtocol {
    private enum State {
        case normal
        case badLine
        case comment
        case key
        case beforeEquals
        case beforeValue
        case value
        case valueWhitespace
        case singleQuote
        case doubleQuote
        case escape
        case awaitingNewline
    }
    
    private var asString: S
    private var asUTF8: S.UTF8View
    private var pos: S.UTF8View.Index
    private var state: State
    
    init(_ string: S) {
        asString = string
        asUTF8 = string.utf8
        pos = asUTF8.startIndex
        state = .normal
    }
    
    mutating func next() -> (String, String)? {
        var chunkStart = pos
        var whitespaceStart = pos
        var key: String = ""
        var quotedValue: String = ""
        
        while pos < asUTF8.endIndex {
            let ch = asUTF8[pos]
            switch state {
            case .normal:
                if ch == 32 || ch == 9 || ch == 13 || ch == 10 {
                    break
                }
                if ch == UInt8(ascii: "#") {
                    state = .comment
                    break
                }
                chunkStart = pos
                state = .key
            case .badLine, .comment, .awaitingNewline:
                if ch == 13 || ch == 10 {
                    state = .normal
                }
            case .key:
                if ch == 32 || ch == 9 {
                    key = String(asString[chunkStart..<pos])
                    state = .beforeEquals
                    break
                }
                if ch == 13 || ch == 10 {
                    state = .normal
                    break
                }
                if ch == UInt8(ascii: "=") {
                    key = String(asString[chunkStart..<pos])
                    state = .beforeValue
                    break
                }
            case .beforeEquals:
                if ch == UInt8(ascii: "=") {
                    state = .beforeValue
                    break
                }
                if ch == 32 || ch == 9 {
                    break
                }
                state = .badLine
            case .beforeValue:
                if ch == 32 || ch == 9 {
                    break
                }
                if ch == UInt8(ascii: "\"") {
                    state = .doubleQuote
                    chunkStart = asUTF8.index(after: pos)
                    quotedValue = ""
                    break
                }
                if ch == UInt8(ascii: "'") {
                    state = .singleQuote
                    chunkStart = asUTF8.index(after: pos)
                    break
                }
                chunkStart = pos
                state = .value
            case .value:
                if ch == 13 || ch == 10 {
                    let value = String(asString[chunkStart..<pos])
                    state = .normal
                    return (key, value)
                }
                if ch == 32 || ch == 9 {
                    state = .valueWhitespace
                    whitespaceStart = pos
                }
            case .valueWhitespace:
                if ch == 13 || ch == 10 {
                    let value = String(asString[chunkStart..<whitespaceStart])
                    state = .normal
                    return (key, value)
                }
                if ch != 32 && ch != 9 {
                    state = .value
                }
            case .singleQuote:
                if ch == UInt8(ascii: "'") {
                    let value = String(asString[chunkStart..<pos])
                    state = .awaitingNewline
                    return (key, value)
                }
            case .doubleQuote:
                if ch == UInt8(ascii: "\\") {
                    let chunk = String(asString[chunkStart..<pos])
                    quotedValue += chunk
                    chunkStart = asUTF8.index(after: pos)
                    state = .escape
                    break
                }
                if ch == UInt8(ascii: "\"") {
                    let chunk = String(asString[chunkStart..<pos])
                    quotedValue += chunk
                    state = .awaitingNewline
                    return (key, quotedValue)
                }
            case .escape:
                let toEscape = asString[chunkStart...pos]
                switch toEscape {
                case "n":
                    quotedValue += "\n"
                case "t":
                    quotedValue += "\t"
                default:
                    quotedValue += toEscape
                }
                chunkStart = asUTF8.index(after: pos)
                state = .doubleQuote
            }
            
            pos = asUTF8.index(after: pos)
        }
        
        return nil
    }
}

func readContents(descriptor: FileDescriptor) throws -> String {
    let length = try descriptor.seek(offset: 0, from: .end)
    
    return try withUnsafeTemporaryAllocation(byteCount: Int(length), alignment: 16) {
        (buffer: UnsafeMutableRawBufferPointer) throws(Errno) -> String in
        
        try descriptor.seek(offset: 0, from: .start)
        let result = try descriptor.read(into: buffer)
        guard result == length else {
            preconditionFailure("unexpected result")
        }
        
        return String(decoding: buffer, as: UTF8.self)
    }
}

private let cfsQuotaPath = "/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
private let cfsPeriodPath = "/sys/fs/cgroup/cpu/cpu.cfs_period_us"
private let cpuSetPath = "/sys/fs/cgroup/cpuset/cpuset.cpus"

private func lineFromFile(at path: String) throws -> Substring {
    let descriptor = try FileDescriptor.open("/etc/os-release", .readOnly)
    let contents = try readContents(descriptor: descriptor)
    return contents.split(separator: "\n").first ?? ""
}

private func countCoreIds(cores: Substring) -> Int? {
    let ids = cores.split(separator: "-", maxSplits: 1)
    guard let first = ids.first.flatMap({ Int($0, radix: 10) }),
          let last = ids.last.flatMap({ Int($0, radix: 10) }),
          last >= first
    else {
        return nil
    }
    return 1 + last - first
}

private func coreCount(cpuset path: String) -> Int? {
    guard let cpuset = try? lineFromFile(at: path).split(separator: ","),
          !cpuset.isEmpty
    else { return nil }
    if let first = cpuset.first, let count = countCoreIds(cores: first) {
        return count
    } else {
        return nil
    }
}

private func coreCount(quota quotaPath: String, period periodPath: String) -> Int? {
    guard let quota = try? Int(lineFromFile(at: quotaPath)),
          quota > 0
    else { return nil }
    guard let period = try? Int(lineFromFile(at: periodPath)),
          period > 0
    else { return nil }
    
    return (quota - 1 + period) / period // always round up if fractional CPU quota requested
}

internal func fsCoreCount() -> Int? {
    if let quota = coreCount(quota: cfsQuotaPath, period: cfsPeriodPath) {
        return quota
    } else if let cpusetCount = coreCount(cpuset: cpuSetPath) {
        return cpusetCount
    } else {
        return nil
    }
}
#endif
