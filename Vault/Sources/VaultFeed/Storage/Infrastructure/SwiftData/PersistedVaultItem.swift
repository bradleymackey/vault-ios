import Foundation
import SwiftData

@Model
final class PersistedVaultItem {
    var id: UUID
    var colorBlue: Double?
    var colorGreen: Double?
    var colorRed: Double?
    var createdDate: Date
    var updatedDate: Date
    var userDescription: String?

    @Relationship(deleteRule: .cascade)
    var noteDetails: PersistedNoteDetails?

    @Relationship(deleteRule: .cascade)
    var otpDetails: PersistedOTPDetails?

    init(createdDate: Date, id: UUID, updatedDate: Date) {
        self.createdDate = createdDate
        self.id = id
        self.updatedDate = updatedDate
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

    init(algorithm: String, authType: String, secretData: Data, secretFormat: String) {
        self.algorithm = algorithm
        self.authType = authType
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

    init(title: String) {
        self.title = title
    }
}

extension PersistedVaultItem {
    static func fetchAll(in context: ModelContext) throws -> [PersistedVaultItem] {
        let descriptor = FetchDescriptor<PersistedVaultItem>(sortBy: [SortDescriptor(\.updatedDate)])
        return try context.fetch(descriptor)
    }

    static func fetch(matchingQuery query: String, in context: ModelContext) throws -> [PersistedVaultItem] {
        let predicate: Predicate<PersistedVaultItem> = #Predicate { item in
            item.queryableStrings.contains { $0.contains(query) }
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.updatedDate)])
        return try context.fetch(descriptor)
    }

    static func first(withID id: UUID, in context: ModelContext) throws -> PersistedVaultItem? {
        var descriptor = FetchDescriptor<PersistedVaultItem>(predicate: #Predicate { item in
            item.id == id
        })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
