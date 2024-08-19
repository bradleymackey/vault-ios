import Foundation
import VaultCore

/// The status of backups made by the user.
///
/// This is saved directly into user defaults to track the last backup.
/// It doesn't need to be encrypted or protected as it doesn't contain any sensitive data.
struct VaultBackupState: Equatable, Hashable, Codable, Sendable {
    /// The date that this backup was made.
    var date: Date
    /// The action that was taken on this backup to reach the current state.
    var action: Action
    /// Hash of all items
    var itemsHash: SHA256Hash
    /// Hash of all tags
    var tagsHash: SHA256Hash
}

extension VaultBackupState {
    enum Action: String, Equatable, Hashable, Codable, Sendable {
        case exportedToPDF = "EXPORTED_TO_PDF"
        case importedFromPDF = "IMPORTED_FROM_PDF"
    }
}
