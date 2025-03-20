public class Allocator<Pointer, E: Error> {
    public private(set) var allocated: Bool = false
    private var value: Pointer?
    private var open: () throws(E) -> Pointer
    private var close: (Pointer) throws(E) -> Void
    
    public init(
        open: @escaping () throws(E) -> Pointer,
        close: @escaping (Pointer) throws(E) -> Void
    ) {
        self.open = open
        self.close = close
    }
    
    deinit {
        try? destroy()
    }
    
    public func allocate() throws(E) -> Pointer {
        defer { allocated = true }
        value = try open()
        return value!
    }
    
    public func destroy() throws(E) {
        guard allocated, let pointer = value else { return }
        defer { allocated = false }
        try close(pointer)
    }
}
