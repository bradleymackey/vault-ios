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

    func createEncryptedBackup(
        userDescription: String,
        items: [VaultItem],
        tags: [VaultItemTag]
    ) throws -> EncryptedVault {
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
            items: items.map {
                itemEncoder.encode(storedItem: $0)
            },
            tags: tags.map {
                tagEncoder.encode(tag: $0)
            },
            userDescription: userDescription
        )
    }
}
