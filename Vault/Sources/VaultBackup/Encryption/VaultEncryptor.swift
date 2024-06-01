import CryptoEngine
import Foundation

final class VaultEncryptor {
    private let encryptor: AESGCMEncryptor
    private let iv: Data
    private let keygenSalt: Data
    private let keygenSignature: ApplicationKeyDeriver.Signature

    init(key: VaultKey, keygenSalt: Data, keygenSignature: ApplicationKeyDeriver.Signature) {
        encryptor = AESGCMEncryptor(key: key.key)
        iv = key.iv
        self.keygenSalt = keygenSalt
        self.keygenSignature = keygenSignature
    }

    func encrypt(encodedVault: IntermediateEncodedVault) throws -> EncryptedVault {
        let encrypted = try encryptor.encrypt(plaintext: encodedVault.data, iv: iv)
        return EncryptedVault(
            data: encrypted.ciphertext,
            authentication: encrypted.authenticationTag,
            encryptionIV: iv,
            keygenSalt: keygenSalt,
            keygenSignature: keygenSignature
        )
    }
}
