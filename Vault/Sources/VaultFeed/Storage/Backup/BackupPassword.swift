import CryptoEngine
import Foundation
import VaultBackup

public struct BackupPassword: Equatable, Hashable, Sendable {
    /// The derived key (via keygen) from the user's password.
    /// (We don't store the password, only the derived key).
    public var key: Data
    /// The salt used in the keygen process to derive `key`.
    public var salt: Data
    /// The keygen that was used to derive this password.
    public var keyDervier: ApplicationKeyDeriver.Signature

    public init(key: Data, salt: Data, keyDervier: ApplicationKeyDeriver.Signature) {
        self.key = key
        self.salt = salt
        self.keyDervier = keyDervier
    }
}

// MARK: - Keygen

extension BackupPassword {
    /// Creates a new encryption key.
    public static func createEncryptionKey(deriver: ApplicationKeyDeriver, password: String) throws -> BackupPassword {
        let salt = Data.random(count: 48)
        let key = try deriver.key(password: Data(password.utf8), salt: salt)
        return BackupPassword(key: key, salt: salt, keyDervier: deriver.signature)
    }

    public func newVaultKeyWithRandomIV() throws -> VaultKey {
        let key = try Key256Bit(data: key)
        return VaultKey.newKeyWithRandomIV(key: key)
    }
}
