import Foundation
import FoundationExtensions

/// A symmetric key used for encryption and decryption.
public struct VaultKey {
    /// The key.
    public var key: KeyData<Bits256>
    /// Initialization vector.
    public var iv: KeyData<Bits256>

    public init(key: KeyData<Bits256>, iv: KeyData<Bits256>) {
        self.key = key
        self.iv = iv
    }
}
