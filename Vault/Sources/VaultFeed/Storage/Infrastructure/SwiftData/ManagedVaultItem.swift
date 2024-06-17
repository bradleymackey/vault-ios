import Foundation
import SwiftData

@Model class ManagedVaultItem {
    var id: UUID
    var colorBlue: Double?
    var colorGreen: Double?
    var colorRed: Double?
    var createdDate: Date
    var updatedDate: Date
    var userDescription: String?
    @Relationship(deleteRule: .cascade) var noteDetails: ManagedNoteDetails?
    @Relationship(deleteRule: .cascade) var otpDetails: ManagedOTPDetails?

    init(createdDate: Date, id: UUID, updatedDate: Date) {
        self.createdDate = createdDate
        self.id = id
        self.updatedDate = updatedDate
    }

    func matches(query: String) -> Bool {
        userDescription?.contains(query) == true ||
            noteDetails?.matches(query: query) == true ||
            otpDetails?.matches(query: query) == true
    }
}

@Model class ManagedOTPDetails {
    var accountName: String?
    var algorithm: String
    var authType: String
    var counter: Int64? = 0
    var digits: Int32 = 0
    var issuer: String?
    var period: Int64? = 0
    var secretData: Data
    var secretFormat: String
    @Relationship(deleteRule: .cascade, inverse: \ManagedVaultItem.otpDetails) var vaultItem: ManagedVaultItem?

    init(algorithm: String, authType: String, secretData: Data, secretFormat: String) {
        self.algorithm = algorithm
        self.authType = authType
        self.secretData = secretData
        self.secretFormat = secretFormat
    }

    func matches(query: String) -> Bool {
        accountName?.contains(query) == true || issuer?.contains(query) == true
    }
}

@Model class ManagedNoteDetails {
    var rawContents: String?
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \ManagedVaultItem.noteDetails) var vaultItem: ManagedVaultItem?

    init(title: String) {
        self.title = title
    }

    func matches(query: String) -> Bool {
        title.contains(query) || rawContents?.contains(query) == true
    }
}

extension ManagedVaultItem {
    static func fetchAll(in context: ModelContext) throws -> [ManagedVaultItem] {
        let descriptor = FetchDescriptor<ManagedVaultItem>(sortBy: [SortDescriptor(\.updatedDate)])
        return try context.fetch(descriptor)
    }

    static func fetch(matchingQuery query: String, in context: ModelContext) throws -> [ManagedVaultItem] {
        let predicate: Predicate<ManagedVaultItem> = #Predicate { item in
            item.matches(query: query)
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.updatedDate)])
        return try context.fetch(descriptor)
    }

    static func first(withID id: UUID, in context: ModelContext) throws -> ManagedVaultItem? {
        var descriptor = FetchDescriptor<ManagedVaultItem>(predicate: #Predicate { item in
            item.id == id
        })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
