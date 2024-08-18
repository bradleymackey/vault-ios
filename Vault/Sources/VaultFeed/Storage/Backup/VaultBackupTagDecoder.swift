import Foundation
import VaultBackup

final class VaultBackupTagDecoder {
    func decode(tag: VaultBackupTag) throws -> VaultItemTag {
        VaultItemTag(
            id: .init(id: tag.id),
            name: tag.title,
            color: decodeColor(color: tag.color),
            iconName: tag.iconName ?? VaultItemTag.defaultIconName
        )
    }
}

extension VaultBackupTagDecoder {
    private func decodeColor(color: VaultBackupRGBColor?) -> VaultItemColor {
        guard let color else { return .tagDefault }
        return .init(red: color.red, green: color.green, blue: color.blue)
    }
}
