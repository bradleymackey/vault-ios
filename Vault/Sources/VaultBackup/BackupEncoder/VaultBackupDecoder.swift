import Foundation
import VaultCore

public final class VaultBackupDecoder {
    private let key: Data

    public init(key: Data) {
        self.key = key
    }

    public func extractBackupPayload(from payload: VaultExportPayload) throws -> VaultBackupPayload {
        let encodedVault = try VaultDecryptor(key: key).decrypt(encryptedVault: payload.encryptedVault)
        let backupPayload = try IntermediateEncodedVaultDecoder().decode(encodedVault: encodedVault)
        return backupPayload
    }
}
