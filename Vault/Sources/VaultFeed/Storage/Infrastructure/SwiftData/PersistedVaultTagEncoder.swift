import Foundation
import SwiftData

struct PersistedVaultTagEncoder {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func encode(tag: VaultItemTag) -> PersistedVaultTag {
        let tag = encodeTagToPersisted(tag)
        // We need to insert the new tag into the context or the backing store
        // for the model is not valid.
        context.insert(tag)
        return tag
    }
}

// MARK: - Helpers

extension PersistedVaultTagEncoder {
    private func encodeTagToPersisted(_ tag: VaultItemTag) -> PersistedVaultTag {
        PersistedVaultTag(
            id: tag.id.id,
            title: tag.name,
            color: encodeColor(tag.color),
            iconName: tag.iconName,
            items: []
        )
    }

    private func encodeColor(_ color: VaultItemColor?) -> PersistedColor? {
        guard let color else { return nil }
        return .init(red: color.red, green: color.green, blue: color.blue)
    }
}
