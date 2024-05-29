import CryptoEngine
import Foundation

final class VaultEncryptor {
    private let encryptor: AESGCMEncryptor
    private let iv: Data

    init(key: VaultKey) {
        encryptor = AESGCMEncryptor(key: key.key)
        iv = key.iv
    }

    func encrypt(encodedVault: IntermediateEncodedVault) throws -> EncryptedVault {
        let encrypted = try encryptor.encrypt(plaintext: encodedVault.data, iv: iv)
        return EncryptedVault(
            data: encrypted.ciphertext,
            authentication: encrypted.authenticationTag,
            encryptionIV: iv
        )
    }
}
