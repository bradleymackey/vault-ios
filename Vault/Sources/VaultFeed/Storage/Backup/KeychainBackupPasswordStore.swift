import CryptoEngine
import Foundation

@Observable
public final class KeychainBackupPasswordStore: BackupPasswordStore {
    private let keychain: SimpleKeychain

    public init(keychain: SimpleKeychain) {
        self.keychain = keychain
    }

    public func fetchPassword() throws -> BackupPassword? {
        do {
            let key = try fetchDataFromKeychainIfPresent(key: KeychainKey.key)
            let salt = try fetchDataFromKeychainIfPresent(key: KeychainKey.salt)
            let deriverData = try fetchDataFromKeychainIfPresent(key: KeychainKey.deriver)
            let deriver = try signatureDecoder().decode(ApplicationKeyDeriver.Signature.self, from: deriverData)
            return BackupPassword(key: key, salt: salt, keyDervier: deriver)
        } catch is NotFoundInKeychain {
            return nil
        }
    }

    public func set(password: BackupPassword) throws {
        try keychain.set(password.key, forKey: KeychainKey.key)
        try keychain.set(password.salt, forKey: KeychainKey.salt)
        let encodedDeriver = try signatureEncoder().encode(password.keyDervier)
        try keychain.set(encodedDeriver, forKey: KeychainKey.deriver)
    }

    struct NotFoundInKeychain: Error {}

    private func fetchDataFromKeychainIfPresent(key: String) throws -> Data {
        if try keychain.hasItem(forKey: key) {
            return try keychain.data(forKey: key)
        } else {
            throw NotFoundInKeychain()
        }
    }

    private func signatureEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        return encoder
    }

    private func signatureDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
}

// MARK: - Keys

extension KeychainBackupPasswordStore {
    private enum KeychainKey {
        static let key = "vault-backup-password-key-v1"
        static let salt = "vault-backup-password-salt-v1"
        static let deriver = "vault-backup-password-deriver-v1"
    }
}
