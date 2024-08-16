import CryptoEngine
import Foundation

public final class BackupPasswordStoreImpl: BackupPasswordStore {
    private let secureStorage: any SecureStorage

    public init(secureStorage: any SecureStorage) {
        self.secureStorage = secureStorage
    }

    public func fetchPassword() throws -> BackupPassword? {
        struct NotFoundInKeychain: Error {}

        func fetchDataFromKeychainIfPresent(key: String) throws -> Data {
            if let item = try secureStorage.retrieve(key: key) {
                item
            } else {
                throw NotFoundInKeychain()
            }
        }

        do {
            let encodedPassword = try fetchDataFromKeychainIfPresent(key: KeychainKey.backupPassword)
            let decoded = try backupPasswordDecoder().decode(BackupPasswordContainer.self, from: encodedPassword)
            return decoded.password
        } catch is NotFoundInKeychain {
            return nil
        }
    }

    public func set(password: BackupPassword) throws {
        let container = BackupPasswordContainer(password: password)
        let encodedPassword = try backupPasswordEncoder().encode(container)
        try secureStorage.store(data: encodedPassword, forKey: KeychainKey.backupPassword)
    }
}

// MARK: - Encoding

extension BackupPasswordStoreImpl {
    /// Codable container that is stored in the keychain.
    private struct BackupPasswordContainer: Codable {
        var key: Data
        var salt: Data
        var keyDervier: ApplicationKeyDeriver.Signature

        init(password: BackupPassword) {
            key = password.key
            salt = password.salt
            keyDervier = password.keyDervier
        }

        var password: BackupPassword {
            BackupPassword(key: key, salt: salt, keyDervier: keyDervier)
        }
    }

    private func backupPasswordEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private func backupPasswordDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private enum KeychainKey {
        static let backupPassword = "vault-backup-password-v1"
    }
}
