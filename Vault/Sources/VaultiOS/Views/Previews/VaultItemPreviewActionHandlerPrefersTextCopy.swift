import Foundation
import VaultFeed

/// Attempts to perform actions in the order provided, or has no action.
final class VaultItemPreviewActionHandlerPrefersTextCopy<each C>: VaultItemPreviewActionHandler
    where repeat each C: VaultItemCopyActionHandler {
        private let copyHandlers: (repeat each C)

        init(copyHandlers: repeat each C) {
            self.copyHandlers = (repeat each copyHandlers)
        }

        func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
            for copyHandler in repeat each copyHandlers {
                if let text = copyHandler.textToCopyForVaultItem(id: id) {
                    return .copyText(text)
                } else {
                    continue
                }
            }

            // If there's no text to copy, then open the item detail.
            return .openItemDetail(id)
        }
    }
