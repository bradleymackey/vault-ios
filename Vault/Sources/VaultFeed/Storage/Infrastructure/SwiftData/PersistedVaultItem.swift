import Foundation
import SwiftData

/// A `VaultItem` persisted to disk using SwiftData.
@Model
final class PersistedVaultItem {
    @Attribute(.unique)
    var id: UUID
    var createdDate: Date
    var updatedDate: Date
    var userDescription: String
    var color: Color?

    @Relationship(deleteRule: .cascade)
    var noteDetails: PersistedNoteDetails?

    @Relationship(deleteRule: .cascade)
    var otpDetails: PersistedOTPDetails?

    struct Color: Codable {
        var red: Double
        var green: Double
        var blue: Double
    }

    init(
        id: UUID,
        createdDate: Date,
        updatedDate: Date,
        userDescription: String,
        color: Color?,
        noteDetails: PersistedNoteDetails?,
        otpDetails: PersistedOTPDetails?
    ) {
        self.id = id
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.userDescription = userDescription
        self.color = color
        self.noteDetails = noteDetails
        self.otpDetails = otpDetails
    }

    var queryableStrings: [String] {
        let strings = [
            userDescription,
            noteDetails?.title,
            noteDetails?.rawContents,
            otpDetails?.accountName,
            otpDetails?.issuer,
        ]
        return strings.compactMap { $0 }
    }
}

@Model
final class PersistedOTPDetails {
    var accountName: String?
    var algorithm: String
    var authType: String
    var counter: Int64? = 0
    var digits: Int32 = 0
    var issuer: String?
    var period: Int64? = 0
    var secretData: Data
    var secretFormat: String

    @Relationship(deleteRule: .cascade, inverse: \PersistedVaultItem.otpDetails)
    var vaultItem: PersistedVaultItem?

    init(
        accountName: String?,
        algorithm: String,
        authType: String,
        counter: Int64? = 0,
        digits: Int32 = 0,
        issuer: String?,
        period: Int64? = 0,
        secretData: Data,
        secretFormat: String
    ) {
        self.accountName = accountName
        self.algorithm = algorithm
        self.authType = authType
        self.counter = counter
        self.digits = digits
        self.issuer = issuer
        self.period = period
        self.secretData = secretData
        self.secretFormat = secretFormat
    }
}

@Model
final class PersistedNoteDetails {
    var rawContents: String?
    var title: String

    @Relationship(deleteRule: .cascade, inverse: \PersistedVaultItem.noteDetails)
    var vaultItem: PersistedVaultItem?

    init(title: String, rawContents: String?) {
        self.title = title
        self.rawContents = rawContents
    }
}
