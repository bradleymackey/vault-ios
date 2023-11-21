import Foundation

/// A full backup of the user's vault.
///
/// This is currently a "version 1" vault backup. It must be maintained for future compatibility in the event that
/// this structure is changed in the future.
public struct VaultBackupPayload: Codable {
    /// Version of this backup, determined when the backup was initially created.
    ///
    /// Determines the decoding structure. This allows for future breaking changes.
    public var version: VaultBackupVersion
    /// The date that the backup was created.
    public var created: Date
    /// Custom user provided desciption attached to the backup.
    public var userDescription: String
    /// The individual items from the vault.
    public var items: [VaultBackupItem]
}

// MARK: - Item

public struct VaultBackupItem: Codable, Equatable, Identifiable {
    /// The underlying ID of the vault item in the application.
    public var id: UUID
    public var createdDate: Date
    public var updatedDate: Date
    public var userDescription: String?
    /// The item's data that is used to reconstruct the item.
    public var item: Item
}

extension VaultBackupItem {
    /// A individual vault item with enough information to reconstruct it.
    public enum Item: Codable, Equatable {
        case otp(data: OTP)
        case note(data: Note)
    }

    /// A backed up OTP code.
    public struct OTP: Codable, Equatable {
        var secretFormat: String
        var secretData: Data
        var authType: String
        var period: Int?
        var counter: Int?
        var algorithm: String
        var digits: Int
        var accountName: String
        var issuer: String?
    }

    /// A backed up secure note.
    public struct Note: Codable, Equatable {
        var title: String
        var rawContents: String?
    }
}
