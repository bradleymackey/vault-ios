import Foundation

// `Schema.Version` in the schema does not seem to be Sendable at this time.
// swiftlint:disable:next no_preconcurrency
@preconcurrency import SwiftData

enum PersistedSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PersistedVaultItem.self, PersistedOTPDetails.self, PersistedNoteDetails.self, PersistedVaultTag.self]
    }
}

extension PersistedSchemaV1 {
    /// A `VaultItem` persisted to disk using SwiftData.
    @Model
    final class PersistedVaultItem {
        @Attribute(.unique)
        var id: UUID
        var relativeOrder: UInt64
        var createdDate: Date
        var updatedDate: Date
        var userDescription: String
        var visibility: String
        var searchableLevel: String
        var searchPassphrase: String?
        var lockState: String?
        var color: PersistedColor?
        @Relationship(deleteRule: .noAction)
        var tags: [PersistedVaultTag] = []

        @Relationship(deleteRule: .cascade)
        var noteDetails: PersistedNoteDetails?

        @Relationship(deleteRule: .cascade)
        var otpDetails: PersistedOTPDetails?

        init(
            id: UUID,
            relativeOrder: UInt64,
            createdDate: Date,
            updatedDate: Date,
            userDescription: String,
            visibility: String,
            searchableLevel: String,
            searchPassphrase: String?,
            lockState: String?,
            color: PersistedColor?,
            tags: [PersistedVaultTag],
            noteDetails: PersistedNoteDetails?,
            otpDetails: PersistedOTPDetails?
        ) {
            self.id = id
            self.relativeOrder = relativeOrder
            self.createdDate = createdDate
            self.updatedDate = updatedDate
            self.userDescription = userDescription
            self.visibility = visibility
            self.searchableLevel = searchableLevel
            self.searchPassphrase = searchPassphrase
            self.lockState = lockState
            self.color = color
            self.tags = tags
            self.noteDetails = noteDetails
            self.otpDetails = otpDetails
        }
    }

    @Model
    final class PersistedOTPDetails {
        var accountName: String
        var issuer: String
        var algorithm: String
        var authType: String
        var counter: Int64? = 0
        var digits: Int32
        var period: Int64? = 0
        var secretData: Data
        var secretFormat: String

        @Relationship(deleteRule: .cascade, inverse: \PersistedVaultItem.otpDetails)
        var vaultItem: PersistedVaultItem?

        init(
            accountName: String,
            issuer: String,
            algorithm: String,
            authType: String,
            counter: Int64? = 0,
            digits: Int32,
            period: Int64? = 0,
            secretData: Data,
            secretFormat: String
        ) {
            self.accountName = accountName
            self.issuer = issuer
            self.algorithm = algorithm
            self.authType = authType
            self.counter = counter
            self.digits = digits
            self.period = period
            self.secretData = secretData
            self.secretFormat = secretFormat
        }
    }

    @Model
    final class PersistedNoteDetails {
        var title: String
        var contents: String
        var format: String

        @Relationship(deleteRule: .cascade, inverse: \PersistedVaultItem.noteDetails)
        var vaultItem: PersistedVaultItem?

        init(title: String, contents: String, format: String) {
            self.title = title
            self.contents = contents
            self.format = format
        }
    }

    /// Represents a tag for items to allow sorting based on this tag.
    @Model
    final class PersistedVaultTag {
        @Attribute(.unique)
        var id: UUID
        var title: String
        var color: PersistedColor?
        var iconName: String?

        @Relationship(deleteRule: .noAction, inverse: \PersistedVaultItem.tags)
        var items: [PersistedVaultItem] = []

        init(id: UUID, title: String, color: PersistedColor?, iconName: String?, items: [PersistedVaultItem]) {
            self.id = id
            self.title = title
            self.color = color
            self.iconName = iconName
            self.items = items
        }
    }
}

extension PersistedVaultTag: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
