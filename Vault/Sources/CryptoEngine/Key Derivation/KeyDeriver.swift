import Foundation
import FoundationExtensions

/// Can derive a key, for example a KDF such as *scrypt*.
///
/// https://en.wikipedia.org/wiki/Key_derivation_function
///
/// @mockable(typealias: Length = Bits256)
public protocol KeyDeriver<Length>: Sendable {
    associatedtype Length: KeyLength
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
