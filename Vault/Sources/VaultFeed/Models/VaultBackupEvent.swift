import CryptoEngine
import Foundation
import VaultCore

/// A record of a backup or sync performed by the user relative to this device.
///
/// Because there's no cloud sync, each individual device will have it's own state in regards to the backup state.
///
/// It doesn't need to be encrypted or protected as it doesn't contain any sensitive data.
public struct VaultBackupEvent: Equatable, Hashable, Codable, Sendable {
    /// The timestamp associated with the backup.
    ///
    /// This is the actual date that the backup was created, not the date that the backup was imported or exported.
    public var backupDate: Date
    /// The date that this backup event was performed (import/export).
    public var eventDate: Date
    /// The action that was taken on this backup to reach the current state.
    public var kind: Kind
    /// Hash of all deterministic data that was backed up (application payload).
    ///
    /// This hash is used to check what data was actually backed up, so no random data or timestamps should be
    /// included in this hash.
    public var payloadHash: Digest<VaultApplicationPayload>.SHA256
}

extension VaultBackupEvent {
    public enum Kind: String, Equatable, Hashable, Sendable, Codable {
        case exportedToPDF = "EXPORT_TO_PDF"
        case importedToPDF = "IMPORT_FROM_PDF"

        public var localizedTitle: String {
            switch self {
            case .exportedToPDF: "Exported to PDF"
            case .importedToPDF: "Imported from PDF"
            }
        }
    }
}
