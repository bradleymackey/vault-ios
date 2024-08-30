import Foundation
import os

// swiftlint:disable no_unchecked_sendable

/// An atomic wrapper for any type, including primitive value types.
/// use this to ensure accesses and modifications are thread safe.
///
/// - note: This is not safe to be used as a property wrapper until
/// "modify accessors" are stabilised in Swift. This is because of implicit
/// copy-on-write within getters/setters that can not work for collections.
public final class Atomic<Value: Sendable>: Sendable {
    @usableFromInline
    let lock: OSAllocatedUnfairLock<Value>

    @inlinable
    public init(initialValue value: Value) {
        lock = .init(initialState: value)
    }

    @inlinable
    public var value: Value {
        lock.withLock { $0 }
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
