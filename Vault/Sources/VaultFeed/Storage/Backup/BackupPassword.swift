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
    public static func makeAppropriateEncryptionKeyDeriver() -> some KeyDeriver {
        #if DEBUG
        // A fast key dervier that is relatively insecure, but runs in <5s in DEBUG on any reasonable hardware.
        return VaultAppKeyDerivers.V1.fast
        #else
        // This is very slow to run in DEBUG, due to lack of optimizations.
        return VaultAppKeyDerivers.V1.secure
        #endif
    }

    /// Creates an encryption key for the v1 version of an encrypted vault.
    public static func createEncryptionKey(deriver: some KeyDeriver, text: String) throws -> BackupPassword {
        let salt = Data.random(count: 48)
        let key = try deriver.key(password: Data(text.utf8), salt: salt)
        return BackupPassword(key: key, salt: salt)
    }
}
