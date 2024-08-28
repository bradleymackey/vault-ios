import CryptoEngine
import Foundation
import VaultBackup
import VaultCore

/// From an encrypted vault, deconstruct to application-level items.
final class BackupImporter {
    private let backupPassword: BackupPassword

    init(backupPassword: BackupPassword) {
        self.backupPassword = backupPassword
    }

    func importEncryptedBackup(encryptedVault: EncryptedVault) throws -> VaultApplicationPayload {
        do {
            let backupDecoder = VaultBackupDecoder(key: backupPassword.key)
            let payload = try backupDecoder.extractBackupPayload(from: encryptedVault)
            let itemDecoder = VaultBackupItemDecoder()
            let tagDecoder = VaultBackupTagDecoder()
            return try .init(
                userDescription: payload.userDescription,
                items: payload.items.map {
                    try itemDecoder.decode(backupItem: $0)
                },
                tags: payload.tags.map {
                    try tagDecoder.decode(tag: $0)
                }
            )
        } catch let decodingError as VaultBackupDecoder.DecodingError {
            switch decodingError {
            case .incompatibleVersion:
                throw ImportError.incompatibleVersion
            case .decryptionFailed:
                throw ImportError.decryption
            case .decodingFailed:
                throw ImportError.decoding
            }
        }
    }
}

// MARK: - Error

extension BackupImporter {
    enum ImportError: Error, LocalizedError {
        case incompatibleVersion
        case decryption
        case decoding

        var errorDescription: String? {
            switch self {
            case .incompatibleVersion: "Incompatible Export Version"
            case .decoding: "Decoding Failed"
            case .decryption: "Decryption Failed"
            }
        }

        var failureReason: String? {
            switch self {
            case .incompatibleVersion:
                return """
                This backup was exported with a different version of the Vault app which is \
                incompatible with this version. You might need to install an older version of the app.
                """
            case .decoding:
                return """
                The data within this backup was able to be decrypted, but it is malformed. \
                This might have been due to an export error or other data tampering. \
                You will need to foresically analyse the export to resolve this.
                """
            case .decryption:
                return """
                Unable to decrypt this Vault. Please check that the decryption password is correct.
                """
            }
        }
    }
}
