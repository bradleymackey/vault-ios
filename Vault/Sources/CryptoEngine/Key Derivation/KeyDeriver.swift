import Foundation
import FoundationExtensions

/// Can derive a key, for example a KDF such as *scrypt*.
///
/// https://en.wikipedia.org/wiki/Key_derivation_function
public protocol KeyDeriver<Length>: Sendable {
    associatedtype Length: KeyLength
    /// Generate a the key using the provided data and parameters.
    ///
    /// Note that as key generation might be expensive, you probably want to run this on a background thread.
    func key(password: Data, salt: Data) throws -> KeyData<Length>
    var uniqueAlgorithmIdentifier: String { get }
}

// MARK: - Helpers

// TODO(#417) - use mockolo
public final class KeyDeriverMock<Length: KeyLength>: KeyDeriver {
    public init() {}

    public let keyCallCount = SharedMutex(0)
    public let keyArgValues: SharedMutex<[(Data, Data)]> = SharedMutex([])
    public let keyHandler: SharedMutex<@Sendable (Data, Data) throws -> KeyData<Length>> = SharedMutex { _, _ in
        .random()
    }

    public func key(password: Data, salt: Data) throws -> KeyData<Length> {
        keyCallCount.modify { $0 += 1 }
        keyArgValues.modify { $0.append((password, salt)) }
        return try keyHandler.get { try $0(password, salt) }
    }

    public let uniqueAlgorithmIdentifierHandler = SharedMutex("mock")
    public var uniqueAlgorithmIdentifier: String { uniqueAlgorithmIdentifierHandler.value }
}

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
    public var uniqueAlgorithmIdentifier: String { "suspending" }
    public var startedKeyDerivationHandler: (@Sendable (Data, Data) throws -> KeyData<Length>) = { _, _ in
        .random()
    }

    private let waiter = DispatchSemaphore(value: 0)

    public init() {}

    /// Derive key. Does not return until signaled via `signalDerivationComplete`.
    public func key(password: Data, salt: Data) throws -> KeyData<Length> {
        let result = try startedKeyDerivationHandler(password, salt)
        waiter.wait()
        return result
    }

    public func signalDerivationComplete() {
        waiter.signal()
    }
}
