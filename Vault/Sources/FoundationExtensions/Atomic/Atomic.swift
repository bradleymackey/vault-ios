import Foundation
import os

// swiftlint:disable no_unchecked_sendable

/// An atomic wrapper for any type, including primitive value types.
/// use this to ensure accesses and modifications are thread safe.
///
/// - note: This is not safe to be used as a property wrapper until
/// "modify accessors" are stabilised in Swift. This is because of implicit
/// copy-on-write within getters/setters that can not work for collections.
public final class Atomic<Value>: @unchecked Sendable {
    @usableFromInline
    var _storage: Value

    @usableFromInline
    let lock = Lock()

    /// Performs the operation in the `block` protected by a lock.
    ///
    /// - note: `block` is not, and cannot, be `async`. Swift's concurrency
    /// model requires that we are able to make forward progress and if this block
    /// were to suspend this could lead to a deadlock (due to the lock surrounding the block).
    @usableFromInline
    func perform<Result>(block: () throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try block()
    }

    @inlinable
    public init(initialValue value: Value) {
        _storage = value
    }

    @inlinable
    public func get<T>(_ block: (Value) throws -> T) rethrows -> T {
        try perform {
            try block(_storage)
        }
    }

    @discardableResult
    @inlinable
    public func modify<T>(_ block: (inout Value) throws -> T) rethrows -> T {
        try perform {
            try block(&_storage)
        }
    }
}
