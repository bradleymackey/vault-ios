import Foundation
import SwiftUI
import VaultCore
import VaultFeed

/// @mockable(typealias: PreviewView = AnyView; PreviewItem = VaultItem.Payload)
@MainActor
public protocol VaultItemPreviewViewGenerator {
    associatedtype PreviewItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(item: PreviewItem, metadata: VaultItem.Metadata, behaviour: VaultItemViewBehaviour)
        -> PreviewView
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

@MainActor
public protocol VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id: UUID) -> String?
}

/// Handle a given action after interacting with a vault item.
@MainActor
public protocol VaultItemPreviewActionHandler {
    func previewActionForVaultItem(id: UUID) -> VaultItemPreviewAction?
}

/// A kind of action that can be taken after interacting with a given vault item.
public enum VaultItemPreviewAction: Equatable {
    case copyText(String)
    case openItemDetail(UUID)
}

// MARK: - Mock

extension VaultItemPreviewViewGeneratorMock: VaultItemCopyActionHandler {
    public func textToCopyForVaultItem(id _: UUID) -> String? {
        nil
    }
}
