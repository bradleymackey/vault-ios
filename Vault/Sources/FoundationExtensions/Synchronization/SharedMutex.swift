import Foundation
import Synchronization

/// An reference-based mutex wrapper for any type, including primitive value types.
/// Use this to ensure accesses and modifications are thread safe.
///
/// As this is a reference type, it can be safely passed between actors without having to adhere to the non-copyable
/// constraints imposed by the `Mutex` type directly.
/// This does mean that the `get`/`modify` closures are `@Sendable` and return `Sendable` types.
///
/// - note: This is not safe to be used as a property wrapper until
/// "modify accessors" are stabilised in Swift. This is because of implicit
/// copy-on-write within getters/setters that can not work for collections.
public final class SharedMutex<Value>: Sendable {
    @usableFromInline
    let lock: Mutex<Value>

    @inlinable
    public init(_ initialValue: consuming sending Value) {
        lock = .init(initialValue)
    }

    @inlinable
    public func get<T: Sendable>(_ block: @Sendable (Value) throws -> T) rethrows -> T {
        try lock.withLock { value in
            try block(value)
        }
    }

    @discardableResult
    @inlinable
    public func modify<T: Sendable>(_ block: @Sendable (inout Value) throws -> T) rethrows -> T {
        try lock.withLock { value in
            try block(&value)
        }
    }
}

extension SharedMutex where Value: Sendable {
    @inlinable
    public var value: Value {
        lock.withLock { $0 }
    }
}
