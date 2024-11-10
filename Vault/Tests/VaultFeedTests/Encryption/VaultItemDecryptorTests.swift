import Foundation
import FoundationExtensions
import TestHelpers
import Testing
@testable import VaultFeed

struct VaultItemDecryptorTests {
    @Test
    func encryptAndDecrypt() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let decryptor = VaultItemDecryptor(key: key)
        let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(item: encryptedItem)

        #expect(decryptedItem == item)
    }

    @Test
    func decryptionFails_returnsDecryptionFailedError() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let invalidKey = DerivedEncryptionKey(key: .random(), salt: .random(count: 12), keyDervier: .testing)
        let decryptor = VaultItemDecryptor(key: invalidKey)

        do {
            let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(item: encryptedItem)
            _ = decryptedItem
        } catch VaultItemDecryptor.Error.decryptionFailed {
            // expected error type
        } catch {
            Issue.record("Unexpected error type, expected decryption failure")
        }
    }

    @Test
    func decodingFailed_returnsDecodingFailedError() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = AESGCMEncryptor(key: key.key.data)
        let iv = Data.random(count: 32)
        let encrypted = try encryptor.encrypt(plaintext: Data("{}".utf8), iv: iv)
        let decryptor = VaultItemDecryptor(key: key)
        let encryptedItem = EncryptedItem(
            title: "ANy",
            data: encrypted.ciphertext,
            authentication: encrypted.authenticationTag,
            encryptionIV: iv,
            keygenSalt: Data(),
            keygenSignature: ""
        )

        do {
            let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(item: encryptedItem)
            _ = decryptedItem
        } catch VaultItemDecryptor.Error.decodingFailed {
            // expected error type
        } catch {
            Issue.record("Unexpected error type, expected decoding failure")
        }
    }
}
