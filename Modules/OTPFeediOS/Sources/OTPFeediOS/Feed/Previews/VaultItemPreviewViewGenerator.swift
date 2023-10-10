import Foundation
import OTPCore
import SwiftUI

@MainActor
public protocol VaultItemPreviewViewGenerator {
    associatedtype VaultItem
    associatedtype PreviewView: View
    func makeVaultPreviewView(id: UUID, code: VaultItem, behaviour: VaultItemViewBehaviour) -> PreviewView
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

public protocol VaultItemCopyTextProvider {
    func currentCopyableText(id: UUID) -> String?
}
