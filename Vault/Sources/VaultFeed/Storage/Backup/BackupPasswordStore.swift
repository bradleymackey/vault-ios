import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable
public protocol BackupPasswordStore: Observable, Sendable {
    func fetchPassword() async throws -> BackupPassword?
    func set(password: BackupPassword) async throws
}
