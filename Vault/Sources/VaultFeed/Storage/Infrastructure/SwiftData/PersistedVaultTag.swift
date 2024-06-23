import Foundation
import SwiftData

/// Represents a tag for items to allow sorting based on this tag.
@Model
final class PersistedVaultTag {
    @Attribute(.unique)
    var id: UUID
    var title: String
    var color: PersistedColor?
    var iconName: String?

    @Relationship(deleteRule: .nullify, inverse: \PersistedVaultItem.tags)
    var items: [PersistedVaultItem] = []

    init(id: UUID, title: String, color: PersistedColor?, iconName: String?, items: [PersistedVaultItem]) {
        self.id = id
        self.title = title
        self.color = color
        self.iconName = iconName
        self.items = items
    }
}

extension PersistedVaultTag: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
