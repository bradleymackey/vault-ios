import CryptoEngine
import Foundation
import FoundationExtensions

final class VaultEncryptor {
    private let encryptor: AESGCMEncryptor
    private let iv: Data
    private let keygenSalt: Data
    private let keygenSignature: ApplicationKeyDeriver<Bits256>.Signature

    init(key: VaultKey, keygenSalt: Data, keygenSignature: ApplicationKeyDeriver<Bits256>.Signature) {
        encryptor = AESGCMEncryptor(key: key.key.data)
        iv = key.iv.data
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
