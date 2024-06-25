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
    }
}
