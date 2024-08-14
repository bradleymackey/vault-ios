import Foundation

public struct VaultApplicationPayload: Sendable, Equatable {
    public var userDescription: String
    public var items: [VaultItem]
    public var tags: [VaultItemTag]

    public init(userDescription: String, items: [VaultItem], tags: [VaultItemTag]) {
        self.userDescription = userDescription
        self.items = items
        self.tags = tags
    }
}
