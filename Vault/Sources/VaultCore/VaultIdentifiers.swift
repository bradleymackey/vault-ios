import Foundation

/// Vault-scoped identifiers for specific pieces of data.
public enum VaultIdentifiers {
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
}
