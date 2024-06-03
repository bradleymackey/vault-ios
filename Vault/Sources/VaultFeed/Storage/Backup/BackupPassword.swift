import CryptoEngine
import Foundation

public struct BackupPassword: Equatable, Hashable {
    public var key: Data
    public var salt: Data

    public init(key: Data, salt: Data) {
        self.key = key
        self.salt = salt
    }
}

// MARK: - Keygen

extension BackupPassword {
    /// Creates a new encryption key.
    public static func createEncryptionKey(deriver: some KeyDeriver, text: String) throws -> BackupPassword {
        let salt = Data.random(count: 48)
        let key = try deriver.key(password: Data(text.utf8), salt: salt)
        return BackupPassword(key: key, salt: salt)
    }
}
