import CryptoEngine
import Foundation
import VaultCore
import VaultKeygen

struct VaultItemEncryptor {
    private let key: DerivedEncryptionKey

    init(key: DerivedEncryptionKey) {
        self.key = key
    }

    /// Encrypts and encodes an encryptable item.
    func encrypt(item: some VaultItemEncryptable) throws -> EncryptedItem {
        let containerEncoding = try item.makeEncryptedContainer()
        let encodedFormat = try makeEncoder().encode(containerEncoding)
        let encryptor = AESGCMEncryptor(key: key.key.data)
        let iv = KeyData<Bits256>.random()
        let encrypted = try encryptor.encrypt(plaintext: encodedFormat, iv: iv.data)
        return EncryptedItem(
            title: containerEncoding.title,
            data: encrypted.ciphertext,
            authentication: encrypted.authenticationTag,
            encryptionIV: iv.data,
            keygenSalt: key.salt,
            keygenSignature: key.keyDervier.rawValue
        )
    }

    /// Decodes and decrypts an encryptable item from the vault.
    func decrypt<T: VaultItemEncryptable>(item: EncryptedItem) throws -> T {
        let decryptor = AESGCMDecryptor(key: key.key.data)
        let item = try decryptor.decrypt(
            message: .init(ciphertext: item.data, authenticationTag: item.authentication),
            iv: item.encryptionIV
        )
        let decoded = try makeDecoder().decode(T.EncryptedContainer.self, from: item)
        return T(encryptedContainer: decoded)
    }

    /// The encoder for the intermediate format before it is encrypted.
    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys] // predictable output
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.dataEncodingStrategy = .base64
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
}
