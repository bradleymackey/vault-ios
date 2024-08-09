import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable
public protocol BackupPasswordStore: Observable, Sendable {
    func checkStorePermission() async throws
    func fetchPassword() throws -> BackupPassword?
    func set(password: BackupPassword) throws
}
