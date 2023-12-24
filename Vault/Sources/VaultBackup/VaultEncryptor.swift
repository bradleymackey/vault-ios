import CryptoEngine
import Foundation

public final class VaultEncryptor {
    private let encryptor: AESGCMEncryptor

    public init(key: VaultKey) {
        encryptor = AESGCMEncryptor(key: key.key, iv: key.iv)
    }

    public func encrypt(data: Data) throws -> EncryptedVault {
        let encrypted = try encryptor.encrypt(plaintext: data)
        return EncryptedVault(data: encrypted.ciphertext, authentication: encrypted.authenticationTag)
    }
}
