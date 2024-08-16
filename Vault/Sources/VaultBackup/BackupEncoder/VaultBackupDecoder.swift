import Foundation
import FoundationExtensions
import VaultCore

public final class VaultBackupDecoder {
    private let key: KeyData<Bits256>

    public init(key: KeyData<Bits256>) {
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
        let encodedVault = try VaultDecryptor(key: key.data).decrypt(encryptedVault: encryptedVault)
        let backupPayload = try IntermediateEncodedVaultDecoder().decode(encodedVault: encodedVault)
        return backupPayload
    }
}
