import Foundation
import VaultFeed

/// Handle a given action after interacting with a vault item.
@MainActor
protocol VaultItemPreviewActionHandler {
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction?
}

/// A kind of action that can be taken after interacting with a given vault item.
enum VaultItemPreviewAction: Equatable {
    case copyText(VaultTextCopyAction)
    case openItemDetail(Identifier<VaultItem>)
}
