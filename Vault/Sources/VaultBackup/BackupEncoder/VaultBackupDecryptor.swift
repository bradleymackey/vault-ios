import Foundation
import FoundationExtensions
import VaultCore

public final class VaultBackupDecryptor {
    private let key: KeyData<Bits256>

    public init(key: KeyData<Bits256>) {
        self.key = key
    }

    public enum Error: Swift.Error {
        case incompatibleVersion
        case decryptionFailed(any Swift.Error)
        case decodingFailed(any Swift.Error)
    }

    public func decryptBackupPayload(from encryptedVault: EncryptedVault) throws -> VaultBackupPayload {
        // Encrypted vault version.
        guard encryptedVault.version.isCompatible(with: "1.0.0") else {
            throw Error.incompatibleVersion
        }
        let encodedVault = try withMappedError {
            try VaultDecryptor(key: key.data).decrypt(encryptedVault: encryptedVault)
        } error: {
            Error.decryptionFailed($0)
        }
        let backupPayload = try withMappedError {
            try IntermediateEncodedVaultDecoder().decode(encodedVault: encodedVault)
        } error: {
            Error.decodingFailed($0)
        }
        return backupPayload
    }
}
