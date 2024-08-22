import CryptoEngine
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

// MARK: - Digestable

extension VaultApplicationPayload: Digestable {
    public var digestableData: some Encodable {
        // The user description is not included in the digest.
        // We only want the digest to represent substantive data so we can compare when data has changed.
        struct DigestPayload<I: Encodable, T: Encodable>: Encodable {
            public var items: [I]
            public var tags: [T]
        }
        return DigestPayload(
            items: items.map(\.digestableData),
            tags: tags.map(\.digestableData)
        )
    }
}
