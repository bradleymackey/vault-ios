import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable(history: fetchPassword = true; history: set = true)
public protocol BackupPasswordStore: Observable {
    func fetchPassword() throws -> BackupPassword?
    func set(password: BackupPassword) throws
}
