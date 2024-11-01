import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: PreviewView = AnyView; PreviewItem = VaultItem.Payload)
@MainActor
public protocol VaultItemPreviewViewGenerator<PreviewItem>: VaultItemPreviewSceneResponder {
    associatedtype PreviewItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(item: PreviewItem, metadata: VaultItem.Metadata, behaviour: VaultItemViewBehaviour)
        -> PreviewView
}

/// A vault item that is able to respond to scene changes.
@MainActor
public protocol VaultItemPreviewSceneResponder {
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

// MARK: - Mock

extension VaultItemPreviewViewGeneratorMock: VaultItemCopyActionHandler {
    public func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> VaultTextCopyAction? {
        nil
    }
}
