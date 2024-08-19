import Foundation
import VaultCore

/// A record of a backup or sync performed by the user relative to this device.
///
/// Because there's no cloud sync, each individual device will have it's own state in regards to the backup state.
///
/// It doesn't need to be encrypted or protected as it doesn't contain any sensitive data.
struct VaultBackupEvent: Equatable, Hashable, Sendable {
    /// The date that this backup was made.
    var date: Date
    /// The action that was taken on this backup to reach the current state.
    var action: Action
    /// Hash of all deterministic data that was backed up (application payload).
    ///
    /// This hash is used to check what data was actually backed up, so no random data or timestamps should be
    /// included in this hash.
    var payloadHash: Hash.SHA256
}

extension VaultBackupEvent {
    enum Action: Equatable, Hashable, Sendable {
        case exportedToPDF
        case importedFromPDF
        case exportedToOtherDevice
        case importedMergedFromOtherDevice
        case importedOverriddenFromOtherDevice
    }
}
