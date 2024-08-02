import Foundation
import SwiftData

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
    @Relationship(deleteRule: .nullify)
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

    @Relationship(deleteRule: .cascade, inverse: \PersistedVaultItem.noteDetails)
    var vaultItem: PersistedVaultItem?

    init(title: String, contents: String) {
        self.title = title
        self.contents = contents
    }
}
