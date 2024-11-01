import Foundation
import VaultFeed

/// Attempts to perform actions in the order provided, or has no action.
final class GenericVaultItemPreviewActionHandler: VaultItemPreviewActionHandler {
    private let childHandlers: [any VaultItemPreviewActionHandler]

    init(childHandlers: [any VaultItemPreviewActionHandler]) {
        self.childHandlers = childHandlers
    }

    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        // Prefer having text to copy, otherwise open item detail.
        for childHandler in childHandlers {
            if let action = childHandler.previewActionForVaultItem(id: id) {
                return action
            }
        }
        return nil
    }
}
