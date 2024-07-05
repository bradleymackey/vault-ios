import CryptoEngine
import Foundation
import SwiftSecurity

@Observable
public final class KeychainBackupPasswordStore: BackupPasswordStore {
    private let keychain: Keychain

    public init(keychain: Keychain) {
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

    private var keychainAccessPolicy: AccessPolicy {
        .init(.whenUnlockedThisDeviceOnly)
    }

    public func set(password: BackupPassword) throws {
        try keychain.store(password.key, query: .credential(for: KeychainKey.key), accessPolicy: keychainAccessPolicy)
        try keychain.store(password.salt, query: .credential(for: KeychainKey.salt), accessPolicy: keychainAccessPolicy)
        let encodedDeriver = try signatureEncoder().encode(password.keyDervier)
        try keychain.store(
            encodedDeriver,
            query: .credential(for: KeychainKey.deriver),
            accessPolicy: keychainAccessPolicy
        )
    }

    struct NotFoundInKeychain: Error {}

    private func fetchDataFromKeychainIfPresent(key: String) throws -> Data {
        if let item = try keychain.retrieve(.credential(for: key)) {
            item
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
