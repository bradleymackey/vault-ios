import Foundation
import VaultFeed

/// Attempts to perform actions in the order provided, or has no action.
final class VaultItemPreviewActionHandlerPrefersTextCopy: VaultItemPreviewActionHandler {
    private let copyHandlers: [any VaultItemCopyActionHandler]

    init(copyHandlers: [any VaultItemCopyActionHandler]) {
        self.copyHandlers = copyHandlers
    }

    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        for copyHandler in copyHandlers {
            if let text = copyHandler.textToCopyForVaultItem(id: id) {
                return .copyText(text)
            }
        }

        // If there's no text to copy, then open the item detail.
        return .openItemDetail(id)
    }
}
