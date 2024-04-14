import Foundation
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
public protocol VaultItemPreviewViewGenerator {
    associatedtype PreviewItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(item: PreviewItem, metadata: StoredVaultItem.Metadata, behaviour: VaultItemViewBehaviour)
        -> PreviewView
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

public protocol VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id: UUID) -> String?
}

/// Handle a given action after interacting with a vault item.
public protocol VaultItemPreviewActionHandler {
    func previewActionForVaultItem(id: UUID) -> VaultItemPreviewAction?
}

/// A kind of action that can be taken after interacting with a given vault item.
public enum VaultItemPreviewAction: Equatable {
    case copyText(String)
    case openItemDetail(UUID)
}
