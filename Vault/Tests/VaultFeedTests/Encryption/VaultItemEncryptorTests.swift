import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

struct VaultItemEncryptorTests {
    @Test
    func encryptAndDecrypt() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let decryptor = VaultItemDecryptor(key: key)
        let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(
            item: encryptedItem,
            expectedItemIdentifier: "test",
        )

        #expect(decryptedItem == item)
    }
}
