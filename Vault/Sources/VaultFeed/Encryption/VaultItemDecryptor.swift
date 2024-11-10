import Foundation
import FoundationExtensions
import VaultKeygen

/// Use for decrypting and decoding encrypted vault items.
///
/// Counterpart to `VaultItemEncryptor`.
struct VaultItemDecryptor {
    private let key: DerivedEncryptionKey

    init(key: DerivedEncryptionKey) {
        self.key = key
    }

    enum Error: Swift.Error {
        case decryptionFailed(any Swift.Error)
        case decodingFailed(any Swift.Error)
    }

    /// Decodes and decrypts an encryptable item from the vault.
    func decrypt<T: VaultItemEncryptable>(item: EncryptedItem) throws -> T {
        let decryptor = AESGCMDecryptor(key: key.key.data)
        let item = try withMappedError {
            try decryptor.decrypt(
                message: .init(ciphertext: item.data, authenticationTag: item.authentication),
                iv: item.encryptionIV
            )
        } error: {
            Error.decryptionFailed($0)
        }
        let decoded = try withMappedError {
            try makeDecoder().decode(T.EncryptedContainer.self, from: item)
        } error: {
            Error.decodingFailed($0)
        }
        return T(encryptedContainer: decoded)
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
}
