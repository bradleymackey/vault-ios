import Foundation

extension VaultKeyDeriver {
    /// Creates a new encryption key from the user-provided password.
    public func createEncryptionKey(password: String) throws -> DerivedEncryptionKey {
        let salt = Data.random(count: 48)
        let key = try key(password: Data(password.utf8), salt: salt)
        return DerivedEncryptionKey(key: key, salt: salt, keyDervier: signature)
    }

    /// Creates an encryption key from the user-provided password, where the salt is pre-determined.
    public func recreateEncryptionKey(password: String, salt: Data) throws -> DerivedEncryptionKey {
        let key = try key(password: Data(password.utf8), salt: salt)
        return DerivedEncryptionKey(key: key, salt: salt, keyDervier: signature)
    }
}
