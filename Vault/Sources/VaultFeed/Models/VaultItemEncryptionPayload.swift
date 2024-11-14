import Foundation
import VaultKeygen

/// A decrypted vault item and the key that was used to encrypt it.
public struct VaultItemEncryptionPayload: Sendable {
    public let decryptedItem: VaultItem
    public let encryptionKey: DerivedEncryptionKey

    public init(decryptedItem: VaultItem, encryptionKey: DerivedEncryptionKey) {
        self.decryptedItem = decryptedItem
        self.encryptionKey = encryptionKey
    }
}
