import Foundation
import SwiftUI
import VaultCore

@MainActor
public protocol VaultItemPreviewViewGenerator {
    associatedtype PreviewItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(id: UUID, item: PreviewItem, behaviour: VaultItemViewBehaviour) -> PreviewView
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

public protocol VaultItemCopyTextProvider {
    func currentCopyableText(id: UUID) -> String?
}
