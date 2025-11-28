import Foundation
import FoundationExtensions

/// Can derive a key, for example a KDF such as *scrypt*.
///
/// https://en.wikipedia.org/wiki/Key_derivation_function
///
/// @mockable
public protocol KeyDeriver<Length>: Sendable {
    associatedtype Length: KeyLength
    /// Generate a the key using the provided data and parameters.
    ///
    /// Note that as key generation might be expensive, you probably want to run this on a background thread.
    func key(password: Data, salt: Data) throws -> KeyData<Length>
    var uniqueAlgorithmIdentifier: String { get }
}

// MARK: - Helpers

public struct FailingKeyDeriver<Length: KeyLength>: KeyDeriver {
    public init() {}

    struct KeyDeriverError: Error {}
    public func key(password _: Data, salt _: Data) throws -> KeyData<Length> {
        throw KeyDeriverError()
    }

    public var uniqueAlgorithmIdentifier: String {
        "failing"
    }
}

/// A key deriver that is able to signal when derivation started.
public struct SuspendingKeyDeriver<Length: KeyLength>: KeyDeriver {
    public typealias Handler = @Sendable (Data, Data) throws -> KeyData<Length>
    public var uniqueAlgorithmIdentifier: String { "suspending" }
    public var handler: Handler

    private let waiter = DispatchSemaphore(value: 0)

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    /// Derive key. Does not return until signaled via `signalDerivationComplete`.
    public func key(password: Data, salt: Data) throws -> KeyData<Length> {
        let result = try handler(password, salt)
        waiter.wait()
        return result
    }

    public func signalDerivationComplete() {
        waiter.signal()
    }
}
