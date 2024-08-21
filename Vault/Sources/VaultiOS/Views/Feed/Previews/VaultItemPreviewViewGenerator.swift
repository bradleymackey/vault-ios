import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

/// @mockable(typealias: PreviewView = AnyView; PreviewItem = VaultItem.Payload)
@MainActor
protocol VaultItemPreviewViewGenerator {
    associatedtype PreviewItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(item: PreviewItem, metadata: VaultItem.Metadata, behaviour: VaultItemViewBehaviour)
        -> PreviewView
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

@MainActor
protocol VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id: Identifier<VaultItem>) -> String?
}

/// Handle a given action after interacting with a vault item.
@MainActor
protocol VaultItemPreviewActionHandler {
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction?
}

/// A kind of action that can be taken after interacting with a given vault item.
enum VaultItemPreviewAction: Equatable {
    case copyText(String)
    case openItemDetail(Identifier<VaultItem>)
}

// MARK: - Mock

extension VaultItemPreviewViewGeneratorMock: VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> String? {
        nil
    }
}
