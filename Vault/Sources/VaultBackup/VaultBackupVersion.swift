import Foundation

/// The version of the vault backup (SEMVER).
///
/// This is used to determine the correct way to decode the vault to be resilient against breaking changes in the
/// structure of the backup itself.
public enum VaultBackupVersion: String, Codable, Equatable, CaseIterable {
    case v1_0_0 = "1.0.0"
}
