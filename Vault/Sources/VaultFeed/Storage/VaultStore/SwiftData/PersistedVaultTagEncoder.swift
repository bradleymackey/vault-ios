import Foundation
import SwiftData

struct PersistedVaultTagEncoder {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func encode(tag: VaultItemTag.Write, importingContext: VaultItemTag.ImportingContext) -> PersistedVaultTag {
        PersistedVaultTag(
            id: importingContext.id.id,
            title: tag.name,
            color: encodeColor(tag.color),
            iconName: tag.iconName,
            items: []
        )
    }

    func encode(tag: VaultItemTag.Write, existing: PersistedVaultTag? = nil) -> PersistedVaultTag {
        let tagItem = if let existing {
            encode(existingTag: existing, newData: tag)
        } else {
            encode(newTag: tag)
        }
        return tagItem
    }
}

// MARK: - Helpers

extension PersistedVaultTagEncoder {
    private func encode(newTag: VaultItemTag.Write) -> PersistedVaultTag {
        PersistedVaultTag(
            id: UUID(),
            title: newTag.name,
            color: encodeColor(newTag.color),
            iconName: newTag.iconName,
            items: []
        )
    }

    private func encode(existingTag: PersistedVaultTag, newData: VaultItemTag.Write) -> PersistedVaultTag {
        existingTag.title = newData.name
        existingTag.color = encodeColor(newData.color)
        existingTag.iconName = newData.iconName
        return existingTag
    }

    private func encodeColor(_ color: VaultItemColor?) -> PersistedColor? {
        guard let color else { return nil }
        return .init(red: color.red, green: color.green, blue: color.blue)
    }
}
