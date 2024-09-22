import Foundation
import FoundationExtensions

/// A key used to encrypt or decrypt a vault.
public struct VaultKey {
    /// The key data for a vault.
    public var key: KeyData<Bits256>
    /// Initialization vector.
    public var iv: KeyData<Bits256>

    public init(key: KeyData<Bits256>, iv: KeyData<Bits256>) {
        self.key = key
        self.iv = iv
    }
}
