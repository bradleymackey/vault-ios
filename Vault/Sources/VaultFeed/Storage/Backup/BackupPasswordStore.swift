import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable
public protocol BackupPasswordStore: Observable, Sendable {
    func fetchPassword() throws -> BackupPassword?
    func set(password: BackupPassword) throws
}
