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

public protocol VaultItemCopyTextProvider {
    func currentCopyableText(id: UUID) -> String?
}
