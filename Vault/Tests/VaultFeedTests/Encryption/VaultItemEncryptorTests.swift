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
        let decryptedItem: VaultItemEncryptableMock = try encryptor.decrypt(item: encryptedItem)

        #expect(decryptedItem == item)
    }
}
