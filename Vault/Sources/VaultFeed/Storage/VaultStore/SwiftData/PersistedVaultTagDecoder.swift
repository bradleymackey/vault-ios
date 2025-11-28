import Foundation

struct PersistedVaultTagDecoder {
    func decode(item: PersistedVaultTag) throws -> VaultItemTag {
        .init(
            id: .init(id: item.id),
            name: item.title,
            color: decodeColor(item.color),
            iconName: item.iconName ?? VaultItemTag.defaultIconName,
        )
    }
}

// MARK: - Helpers

extension PersistedVaultTagDecoder {
    private func decodeColor(_ color: PersistedColor?) -> VaultItemColor {
        guard let color else { return .tagDefault }
        return .init(red: color.red, green: color.green, blue: color.blue)
    }
}
