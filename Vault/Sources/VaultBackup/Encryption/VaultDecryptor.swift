import CryptoEngine
import Foundation

public final class VaultDecryptor {
    private let decryptor: AESGCMDecryptor
    public init(key: VaultKey) {
        decryptor = AESGCMDecryptor(key: key.key, iv: key.iv)
    }

    public func decrypt(encryptedVault: EncryptedVault) throws -> EncodedVault {
        let decrypted = try decryptor.decrypt(
            message: .init(ciphertext: encryptedVault.data, authenticationTag: encryptedVault.authentication)
        )
        return EncodedVault(data: decrypted)
    }
}
