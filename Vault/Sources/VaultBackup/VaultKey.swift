import Foundation

/// A key used to encrypt or decrypt a vault.
public struct VaultKey {
    /// The key data for a vault.
    public var key: Data
    /// Initialization vector.
    public var iv: Data

    enum KeyError: Error {
        case invalidLength
    }

    enum IVError: Error {
        case invalidLength
    }

    public init(key: Data, iv: Data) throws {
        guard key.count == 32 else { throw KeyError.invalidLength }
        guard iv.count == 32 else { throw IVError.invalidLength }
        self.key = key
        self.iv = iv
    }
}
