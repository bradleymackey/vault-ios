import Foundation

final class KeychainBackupPasswordStore: BackupPasswordStore {
    private let keychain: SimpleKeychain

    init(keychain: SimpleKeychain) {
        self.keychain = keychain
    }

    func fetchPassword() throws -> BackupPassword? {
        let key = try fetchFromKeychainIfPresent(key: KeychainKey.key)
        let salt = try fetchFromKeychainIfPresent(key: KeychainKey.salt)
        guard let key, let salt else { return nil }
        return BackupPassword(key: key, salt: salt)
    }

    func set(password: BackupPassword) throws {
        try keychain.set(password.key, forKey: KeychainKey.key)
        try keychain.set(password.salt, forKey: KeychainKey.salt)
    }

    private func fetchFromKeychainIfPresent(key: String) throws -> Data? {
        if try keychain.hasItem(forKey: key) {
            return try keychain.data(forKey: key)
        } else {
            return nil
        }
    }
}

// MARK: - Keys

extension KeychainBackupPasswordStore {
    private enum KeychainKey {
        static let key = "vault-backup-password-key-v1"
        static let salt = "vault-backup-password-salt-v1"
    }
}
