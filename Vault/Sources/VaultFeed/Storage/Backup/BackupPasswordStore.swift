import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable
public protocol BackupPasswordStore: Observable, Sendable {
    func fetchPassword() async throws -> DerivedEncryptionKey?
    func set(password: DerivedEncryptionKey) async throws
}
