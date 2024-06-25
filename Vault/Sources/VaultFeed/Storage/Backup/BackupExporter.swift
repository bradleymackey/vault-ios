import CryptoEngine
import Foundation
import VaultBackup
import VaultCore

/// From an application-level vault, create the encrypted vault.
final class BackupExporter {
    private let clock: EpochClock
    private let backupPassword: BackupPassword

    init(clock: EpochClock, backupPassword: BackupPassword) {
        self.clock = clock
        self.backupPassword = backupPassword
    }

    func createEncryptedBackup(payload: VaultApplicationPayload) throws -> EncryptedVault {
        let encryptionKey = try backupPassword.newVaultKeyWithRandomIV()
        let backupEncoder = VaultBackupEncoder(
            clock: clock,
            key: encryptionKey,
            keygenSalt: backupPassword.salt,
            keygenSignature: backupPassword.keyDervier,
            paddingMode: .random
        )
        let itemEncoder = VaultBackupItemEncoder()
        let tagEncoder = VaultBackupTagEncoder()
        return try backupEncoder.createExportPayload(
            items: payload.items.map {
                itemEncoder.encode(storedItem: $0)
            },
            tags: payload.tags.map {
                tagEncoder.encode(tag: $0)
            },
            userDescription: payload.userDescription
        )
    }
}
