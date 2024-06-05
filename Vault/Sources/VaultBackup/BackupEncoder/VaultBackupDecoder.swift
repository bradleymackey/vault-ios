import Foundation
import VaultCore

public final class VaultBackupDecoder {
    private let key: Data

    public init(key: Data) {
        self.key = key
    }

    public enum DecodingError: Error {
        case incompatibleVersion
    }

    public func extractBackupPayload(from encryptedVault: EncryptedVault) throws -> VaultBackupPayload {
        // Encrypted vault version.
        guard encryptedVault.version.isCompatible(with: "1.0.0") else {
            throw DecodingError.incompatibleVersion
        }
        let encodedVault = try VaultDecryptor(key: key).decrypt(encryptedVault: encryptedVault)
        let backupPayload = try IntermediateEncodedVaultDecoder().decode(encodedVault: encodedVault)
        return backupPayload
    }
}
