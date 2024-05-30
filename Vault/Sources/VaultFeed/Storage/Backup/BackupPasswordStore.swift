import Foundation

/// Storage for the password used to encrypt backups.
///
/// @mockable(history: password = true)
public protocol BackupPasswordStore {
    var password: BackupPassword? { get set }
}
