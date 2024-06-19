import Foundation
import FoundationExtensions

/// A full backup of the user's vault.
///
/// This is currently a "version 1" vault backup. It must be maintained for future compatibility in the event that
/// this structure is changed in the future.
public struct VaultBackupPayload: Codable, Equatable {
    /// Version of this backup, determined when the backup was initially created.
    ///
    /// Determines the decoding structure. This allows for future breaking changes.
    public var version: SemVer
    /// The date that the backup was created.
    public var created: Date
    /// Custom user provided desciption attached to the backup.
    public var userDescription: String
    /// The individual items from the vault.
    public var items: [VaultBackupItem]
    /// Arbitrary padding used to disguise the actual size of the payload.
    /// This is a security requirement as users may have hidden items in their vault.
    ///
    /// This should be sufficient to disguise the number of items in the payload, but not
    /// so large to make the payload hard to handle.
    var obfuscationPadding: Data
}

// MARK: - Item

public struct VaultBackupItem: Codable, Equatable, Identifiable {
    /// The underlying ID of the vault item in the application.
    public var id: UUID
    public var createdDate: Date
    public var updatedDate: Date
    public var userDescription: String
    public var visibility: Visibility
    public var searchableLevel: SearchableLevel
    public var searchPassphrase: String?
    /// The tint color associated with the item.
    public var tintColor: RGBColor?
    /// The item's data that is used to reconstruct the item.
    public var item: Item

    public init(
        id: UUID,
        createdDate: Date,
        updatedDate: Date,
        userDescription: String,
        visibility: Visibility,
        searchableLevel: SearchableLevel,
        searchPassphrase: String? = nil,
        tintColor: RGBColor? = nil,
        item: Item
    ) {
        self.id = id
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.userDescription = userDescription
        self.visibility = visibility
        self.searchableLevel = searchableLevel
        self.searchPassphrase = searchPassphrase
        self.tintColor = tintColor
        self.item = item
    }
}

extension VaultBackupItem {
    /// A individual vault item with enough information to reconstruct it.
    public enum Item: Codable, Equatable {
        case otp(data: OTP)
        case note(data: Note)
    }

    public struct RGBColor: Codable, Equatable {
        public var red, green, blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }

    public enum SearchableLevel: String, Codable {
        case none = "NONE"
        case full = "FULL"
        case onlyTitle = "ONLY_TITLE"
        case onlyPassphrase = "ONLY_PASSPHRASE"
    }

    public enum Visibility: String, Codable {
        case always = "ALWAYS"
        case onlySearch = "ONLY_SEARCH"
    }

    /// A backed up OTP code.
    public struct OTP: Codable, Equatable {
        public var secretFormat: String
        public var secretData: Data
        public var authType: String
        public var period: UInt64?
        public var counter: UInt64?
        public var algorithm: String
        public var digits: UInt16
        public var accountName: String
        public var issuer: String

        public init(
            secretFormat: String,
            secretData: Data,
            authType: String,
            period: UInt64? = nil,
            counter: UInt64? = nil,
            algorithm: String,
            digits: UInt16,
            accountName: String,
            issuer: String = ""
        ) {
            self.secretFormat = secretFormat
            self.secretData = secretData
            self.authType = authType
            self.period = period
            self.counter = counter
            self.algorithm = algorithm
            self.digits = digits
            self.accountName = accountName
            self.issuer = issuer
        }
    }

    /// A backed up secure note.
    public struct Note: Codable, Equatable {
        public var title: String
        public var rawContents: String?

        public init(title: String, rawContents: String? = nil) {
            self.title = title
            self.rawContents = rawContents
        }
    }
}
