import CryptoEngine
import Foundation
import SwiftSecurity

@Observable
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
            let key = try fetchDataFromKeychainIfPresent(key: KeychainKey.key)
            let salt = try fetchDataFromKeychainIfPresent(key: KeychainKey.salt)
            let deriverData = try fetchDataFromKeychainIfPresent(key: KeychainKey.deriver)
            let deriver = try signatureDecoder().decode(ApplicationKeyDeriver.Signature.self, from: deriverData)
            return BackupPassword(key: key, salt: salt, keyDervier: deriver)
        } catch is NotFoundInKeychain {
            return nil
        }
    }

    private var keychainAccessPolicy: AccessPolicy {
        .init(.whenUnlockedThisDeviceOnly)
    }

    public func set(password: BackupPassword) throws {
        try secureStorage.store(data: password.key, forKey: KeychainKey.key)
        try secureStorage.store(data: password.salt, forKey: KeychainKey.salt)
        let encodedDeriver = try signatureEncoder().encode(password.keyDervier)
        try secureStorage.store(data: encodedDeriver, forKey: KeychainKey.deriver)
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

extension BackupPasswordStoreImpl {
    private enum KeychainKey {
        static let key = "vault-backup-password-key-v1"
        static let salt = "vault-backup-password-salt-v1"
        static let deriver = "vault-backup-password-deriver-v1"
    }
}
