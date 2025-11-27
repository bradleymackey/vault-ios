import Foundation
import VaultBackup

/// Encodes the global tag `VaultItemTag` to a `VaultBackupTag` ready for use in the
/// backup and encryption engine.
final class VaultBackupTagEncoder {
    func encode(tag: VaultItemTag) -> VaultBackupTag {
        VaultBackupTag(
            id: tag.id.id,
            title: tag.name,
            color: encodeColor(tag: tag),
            iconName: tag.iconName,
        )
    }
}

extension VaultBackupTagEncoder {
    private func encodeColor(tag: VaultItemTag) -> VaultBackupRGBColor? {
        let color = tag.color
        return .init(red: color.red, green: color.green, blue: color.blue)
    }
}
