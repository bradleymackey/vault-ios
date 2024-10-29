import Foundation
import SwiftUI
import VaultFeed

/// A `VaultItemPreviewViewGenerator` that is able to perform basic actions.
typealias ActionableVaultItemPreviewViewGenerator<PreviewItem> = VaultItemCopyActionHandler &
    VaultItemPreviewActionHandler & VaultItemPreviewViewGenerator<PreviewItem>

/// @mockable(typealias: PreviewView = AnyView; PreviewItem = VaultItem.Payload)
@MainActor
protocol VaultItemPreviewViewGenerator<PreviewItem>: VaultItemPreviewSceneResponder {
    associatedtype PreviewItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(item: PreviewItem, metadata: VaultItem.Metadata, behaviour: VaultItemViewBehaviour)
        -> PreviewView
}

/// A vault item that is able to respond to scene changes.
@MainActor
protocol VaultItemPreviewSceneResponder {
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

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

// MARK: - Mock

extension VaultItemPreviewViewGeneratorMock: VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> VaultTextCopyAction? {
        nil
    }
}
