import CryptoEngine
import Foundation

final class VaultDecryptor {
    private let decryptor: AESGCMDecryptor
    init(key: Data) {
        decryptor = AESGCMDecryptor(key: key)
    }

    func decrypt(encryptedVault: EncryptedVault) throws -> IntermediateEncodedVault {
        let decrypted = try decryptor.decrypt(
            message: .init(ciphertext: encryptedVault.data, authenticationTag: encryptedVault.authentication),
            iv: encryptedVault.encryptionIV
        )
        return IntermediateEncodedVault(data: decrypted)
    }
}
