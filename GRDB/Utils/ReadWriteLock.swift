import Dispatch

/// A ReadWriteLock grants multiple readers and single-writer guarantees on a
/// value. It is backed by a concurrent DispatchQueue.
final class ReadWriteLock<T> {
    private var _value: T
    private var queue: DispatchQueue
    
    var value: T {
        get { read { $0 } }
        set { withLock { $0 = newValue } }
    }
    
    init(_ value: T) {
        _value = value
        queue = DispatchQueue(label: "GRDB.ReadWriteLock", attributes: [.concurrent])
    }
    
    /// Reads the value.
    func read<U>(_ body: (T) throws -> U) rethrows -> U {
        try queue.sync {
            try body(_value)
        }
    }
    
    /// Runs the provided closure while holding a lock on the value.
    ///
    /// - parameter body: A closure that can modify the value.
    func withLock<U>(_ body: (inout T) throws -> U) rethrows -> U {
        try queue.sync(flags: [.barrier]) {
            try body(&_value)
        }
    }
}

// @unchecked because `_wrappedValue` is protected by `queue`
extension ReadWriteLock: @unchecked Sendable where T: Sendable { }

extension ReadWriteLock where T: Numeric {
    @discardableResult
    func increment() -> T {
        withLock { n in
            n += 1
            return n
        }
    }
    
    @discardableResult
    func decrement() -> T {
        withLock { n in
            n -= 1
            return n
        }
    }
}