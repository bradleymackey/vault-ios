import Foundation

/// A key used to encrypt or decrypt a vault.
public struct VaultKey {
    /// The key data for a vault.
    public var key: Data
    /// Initialization vector.
    public var iv: Data

    enum KeyError: Error, LocalizedError {
        case invalidLength(length: Int)

        var errorDescription: String? {
            switch self {
            case let .invalidLength(length):
                "The vault key must be 32 bytes long. The provided key was \(length) bytes."
            }
        }
    }

    enum IVError: Error {
        case invalidLength(length: Int)

        var errorDescription: String? {
            switch self {
            case let .invalidLength(length):
                "The vault IV must be 32 bytes long. The provided key was \(length) bytes."
            }
        }
    }

    public init(key: Data, iv: Data) throws {
        guard key.count == 32 else { throw KeyError.invalidLength(length: key.count) }
        guard iv.count == 32 else { throw IVError.invalidLength(length: iv.count) }
        self.key = key
        self.iv = iv
    }

    /// Creates a new key with a random IV.
    public static func newKeyWithRandomIV(key: Data) throws -> VaultKey {
        let iv = Data.random(count: 32)
        return try .init(key: key, iv: iv)
    }
}
