import Foundation

// `Schema.Version` in the schema does not seem to be Sendable at this time.
// swiftlint:disable:next no_preconcurrency
@preconcurrency import SwiftData

enum PersistedSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PersistedVaultItem.self, PersistedOTPDetails.self, PersistedNoteDetails.self, PersistedVaultTag.self]
    }
}

extension PersistedSchemaV3 {
    /// A `VaultItem` persisted to disk using SwiftData.
    ///
    /// V3 replaces the V2 plaintext `searchPassphrase: String?` field with a
    /// one-way `(searchPassphraseSalt, searchPassphraseDigest)` pair so that
    /// a vault database leak cannot expose search passphrases verbatim. The
    /// pair is `nil` when no passphrase is set, and either both are non-nil
    /// or both are nil — never one without the other.
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
        var searchPassphraseSalt: Data?
        var searchPassphraseDigest: Data?
        var killphraseSalt: Data?
        var killphraseDigest: Data?
        var lockState: String?
        var color: PersistedColor?
        var showInQuickType: Bool = true
        var previewMode: String = NotePreviewMode.titleAndFirstLine.rawValue
        @Relationship(deleteRule: .noAction)
        var tags: [PersistedVaultTag] = []

        @Relationship(deleteRule: .cascade)
        var noteDetails: PersistedNoteDetails?
        @Relationship(deleteRule: .cascade)
        var otpDetails: PersistedOTPDetails?
        @Relationship(deleteRule: .cascade)
        var encryptedItemDetails: PersistedEncryptedItemDetails?

        init(
            id: UUID,
            relativeOrder: UInt64,
            createdDate: Date,
            updatedDate: Date,
            userDescription: String,
            visibility: String,
            searchableLevel: String,
            searchPassphraseSalt: Data?,
            searchPassphraseDigest: Data?,
            killphraseSalt: Data?,
            killphraseDigest: Data?,
            lockState: String?,
            color: PersistedColor?,
            showInQuickType: Bool,
            previewMode: String,
            tags: [PersistedVaultTag],
            noteDetails: PersistedNoteDetails?,
            otpDetails: PersistedOTPDetails?,
            encryptedItemDetails: PersistedEncryptedItemDetails?,
        ) {
            self.id = id
            self.relativeOrder = relativeOrder
            self.createdDate = createdDate
            self.updatedDate = updatedDate
            self.userDescription = userDescription
            self.visibility = visibility
            self.searchableLevel = searchableLevel
            self.searchPassphraseSalt = searchPassphraseSalt
            self.searchPassphraseDigest = searchPassphraseDigest
            self.killphraseSalt = killphraseSalt
            self.killphraseDigest = killphraseDigest
            self.lockState = lockState
            self.color = color
            self.showInQuickType = showInQuickType
            self.previewMode = previewMode
            self.tags = tags
            self.noteDetails = noteDetails
            self.otpDetails = otpDetails
            self.encryptedItemDetails = encryptedItemDetails
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
            secretFormat: String,
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

    @Model
    final class PersistedEncryptedItemDetails {
        var version: String
        var title: String
        var data: Data
        var authentication: Data
        var encryptionIV: Data
        var keygenSalt: Data
        var keygenSignature: String

        @Relationship(deleteRule: .cascade, inverse: \PersistedVaultItem.encryptedItemDetails)
        var vaultItem: PersistedVaultItem?

        init(
            version: String,
            title: String,
            data: Data,
            authentication: Data,
            encryptionIV: Data,
            keygenSalt: Data,
            keygenSignature: String,
        ) {
            self.version = version
            self.title = title
            self.data = data
            self.authentication = authentication
            self.encryptionIV = encryptionIV
            self.keygenSalt = keygenSalt
            self.keygenSignature = keygenSignature
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

extension PersistedSchemaV3.PersistedVaultTag: Swift.Hashable {
    func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(id)
    }
}
