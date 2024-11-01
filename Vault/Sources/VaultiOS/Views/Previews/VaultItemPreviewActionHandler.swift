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

final class ShowItemDetailVaultItemPreviewActionHandler: VaultItemPreviewActionHandler {
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        .openItemDetail(id)
    }
}

extension VaultItemPreviewActionHandler where Self == ShowItemDetailVaultItemPreviewActionHandler {
    static var showItemDetail: Self { .init() }
}

final class CopyTextVaultItemPreviewActionHandler: VaultItemPreviewActionHandler {
    private let copyHandler: any VaultItemCopyActionHandler

    init(copyHandler: any VaultItemCopyActionHandler) {
        self.copyHandler = copyHandler
    }

    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        guard let copy = copyHandler.textToCopyForVaultItem(id: id) else {
            return nil
        }
        return .copyText(copy)
    }
}

extension VaultItemPreviewActionHandler where Self == CopyTextVaultItemPreviewActionHandler {
    static func copyText(_ handler: any VaultItemCopyActionHandler) -> Self {
        .init(copyHandler: handler)
    }
}
