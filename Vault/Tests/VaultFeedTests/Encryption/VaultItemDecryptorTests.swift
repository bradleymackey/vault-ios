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
        let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(
            item: encryptedItem,
            expectedItemIdentifier: "test",
        )

        #expect(decryptedItem == item)
    }

    @Test
    func decrypt_returnsDecryptionFailedError() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let invalidKey = DerivedEncryptionKey(key: .random(), salt: .random(count: 12), keyDervier: .testing)
        let decryptor = VaultItemDecryptor(key: invalidKey)

        do {
            let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(
                item: encryptedItem,
                expectedItemIdentifier: "test",
            )
            _ = decryptedItem
        } catch VaultItemDecryptor.Error.decryptionFailed {
            // expected error type
        } catch {
            Issue.record("Unexpected error type, expected decryption failure")
        }
    }

    @Test
    func decrypt_returnsDecodingFailedError() throws {
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = AESGCMEncryptor(key: key.key.data)
        let iv = Data.random(count: 32)
        let encrypted = try encryptor.encrypt(plaintext: Data("{}".utf8), iv: iv)
        let decryptor = VaultItemDecryptor(key: key)
        let encryptedItem = EncryptedItem(
            version: "1.0.0",
            title: "ANy",
            data: encrypted.ciphertext,
            authentication: encrypted.authenticationTag,
            encryptionIV: iv,
            keygenSalt: Data(),
            keygenSignature: "",
        )

        do {
            let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(
                item: encryptedItem,
                expectedItemIdentifier: "test",
            )
            _ = decryptedItem
        } catch VaultItemDecryptor.Error.decodingFailed {
            // expected error type
        } catch {
            Issue.record("Unexpected error type, expected decoding failure")
        }
    }

    @Test
    func decrypt_mismatchedItemIdentifier() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let decryptor = VaultItemDecryptor(key: key)

        do {
            let decryptedItem: VaultItemEncryptableMock = try decryptor.decrypt(
                item: encryptedItem,
                expectedItemIdentifier: "invalid",
            )
            _ = decryptedItem
        } catch let VaultItemDecryptor.Error.mismatchedItemIdentifier(expected, actual) {
            #expect(expected == "invalid")
            #expect(actual == "test")
        } catch {
            Issue.record("Unexpected error type, expected type mismatch")
        }
    }

    @Test
    func decryptItemIdentifier_returnsItemIdentifier() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let decryptor = VaultItemDecryptor(key: key)

        let identifier = try decryptor.decryptItemIdentifier(item: encryptedItem)

        #expect(identifier == "test")
    }

    @Test
    func decryptItemIdentifier_decryptionFailedError() throws {
        let id = UUID()
        let item = VaultItemEncryptableMock(id: id)
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = VaultItemEncryptor(key: key)
        let encryptedItem = try encryptor.encrypt(item: item)
        let invalidKey = DerivedEncryptionKey(key: .random(), salt: .random(count: 12), keyDervier: .testing)
        let decryptor = VaultItemDecryptor(key: invalidKey)

        do {
            _ = try decryptor.decryptItemIdentifier(item: encryptedItem)
        } catch VaultItemDecryptor.Error.decryptionFailed {
            // expected error type
        } catch {
            Issue.record("Unexpected error type, expected decryption failure")
        }
    }

    @Test
    func decryptItemIdentifier_decodingFailedError() throws {
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)
        let encryptor = AESGCMEncryptor(key: key.key.data)
        let iv = Data.random(count: 32)
        let encrypted = try encryptor.encrypt(plaintext: Data("{}".utf8), iv: iv)
        let decryptor = VaultItemDecryptor(key: key)
        let encryptedItem = EncryptedItem(
            version: "1.0.0",
            title: "ANy",
            data: encrypted.ciphertext,
            authentication: encrypted.authenticationTag,
            encryptionIV: iv,
            keygenSalt: Data(),
            keygenSignature: "",
        )

        do {
            _ = try decryptor.decryptItemIdentifier(item: encryptedItem)
        } catch VaultItemDecryptor.Error.decodingFailed {
            // expected error type
        } catch {
            Issue.record("Unexpected error type, expected decoding failure")
        }
    }
}
