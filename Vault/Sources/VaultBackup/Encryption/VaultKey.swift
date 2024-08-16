import Foundation
import FoundationExtensions

/// A key used to encrypt or decrypt a vault.
public struct VaultKey {
    /// The key data for a vault.
    public var key: Key256Bit
    /// Initialization vector.
    public var iv: Key256Bit

    public init(key: Key256Bit, iv: Key256Bit) {
        self.key = key
        self.iv = iv
    }

    /// Creates a new key with a random IV.
    public static func newKeyWithRandomIV(key: Key256Bit) -> VaultKey {
        .init(key: key, iv: .random())
    }
}
