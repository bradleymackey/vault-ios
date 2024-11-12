import Foundation

/// Vault-scoped identifiers for specific pieces of data.
public enum VaultIdentifiers {
    public enum Item {
        public static let secureNote = "vault.item.secure-note.v1"
        public static let otpCode = "vault.item.otp-code.v1"
    }

    public enum SecureStorageKey {
        public static let backupPassword = "vault.secure-storage.backup-password.v1"
    }

    public enum Backup {
        public static let encryptedVaultData = "vault.backup.encrypted-vault"
        public static let lastBackupEvent = "vault.backup.last-event"
    }

    public enum Preferences {
        public enum PDF {
            public static let defaultSize = "vault.preferences.pdf.default-size"
            public static let userHint = "vault.preferences.pdf.user-hint"
        }

        public enum General {
            public static let settingsPasteTTL = "vault.preferences.general.settings-paste-ttl"
        }
    }

    public enum CodeScanning {
        public static let simulatedCode = "vault.codescanning.simulated-code"
    }
}
