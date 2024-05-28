import CryptoEngine
import Foundation

final class VaultDecryptor {
    private let decryptor: AESGCMDecryptor
    init(key: VaultKey) {
        decryptor = AESGCMDecryptor(key: key.key, iv: key.iv)
    }

    func decrypt(encryptedVault: EncryptedVault) throws -> IntermediateEncodedVault {
        let decrypted = try decryptor.decrypt(
            message: .init(ciphertext: encryptedVault.data, authenticationTag: encryptedVault.authentication)
        )
        return IntermediateEncodedVault(data: decrypted)
    }
}
