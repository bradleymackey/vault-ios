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

    func importEncryptedBackup() {}
}
