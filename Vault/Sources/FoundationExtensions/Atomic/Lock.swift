import Foundation

// swiftlint:disable no_unchecked_sendable

/// An efficient lock to prevent contesting access to a resource across threads
///
/// This is a very thin wrapper around `os_unfair_lock` with a better Swift interface.
/// It also has a similar interface to `NSLock`
public final class Lock: @unchecked Sendable {
    @usableFromInline
    var _mutex = os_unfair_lock()

    public init() {}
}

extension Lock {
    /// Locks the `Lock`. Blocks if it is already locked.
    @inlinable
    public func lock() {
        os_unfair_lock_lock(&_mutex)
    }

    /// Unlocks the `Lock`.
    @inlinable
    public func unlock() {
        os_unfair_lock_unlock(&_mutex)
    }

    /// Locks the `Lock` if it is not already locked.
    ///
    /// It is invalid to call this in a retry loop.
    /// The program must be able to proceed without having aquired the lock.
    @inlinable
    public func `try`() -> Bool {
        os_unfair_lock_trylock(&_mutex)
    }
}
