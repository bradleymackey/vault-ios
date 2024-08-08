import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable
public protocol BackupPasswordStore: Observable {
    func checkStorePermission() async throws
    func fetchPassword() throws -> BackupPassword?
    func set(password: BackupPassword) throws
}
