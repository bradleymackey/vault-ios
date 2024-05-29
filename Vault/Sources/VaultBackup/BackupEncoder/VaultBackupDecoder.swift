import Foundation
import VaultCore

public final class VaultBackupDecoder {
    private let key: Data

    public init(key: Data) {
        self.key = key
    }

    public func extractBackupPayload(from encryptedVault: EncryptedVault) throws -> VaultBackupPayload {
        let encodedVault = try VaultDecryptor(key: key).decrypt(encryptedVault: encryptedVault)
        let backupPayload = try IntermediateEncodedVaultDecoder().decode(encodedVault: encodedVault)
        return backupPayload
    }
}
