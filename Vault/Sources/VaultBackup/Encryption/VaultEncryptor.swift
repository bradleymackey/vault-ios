import CryptoEngine
import Foundation

final class VaultEncryptor {
    private let encryptor: AESGCMEncryptor

    init(key: VaultKey) {
        encryptor = AESGCMEncryptor(key: key.key, iv: key.iv)
    }

    func encrypt(encodedVault: IntermediateEncodedVault) throws -> EncryptedVault {
        let encrypted = try encryptor.encrypt(plaintext: encodedVault.data)
        return EncryptedVault(data: encrypted.ciphertext, authentication: encrypted.authenticationTag)
    }
}
