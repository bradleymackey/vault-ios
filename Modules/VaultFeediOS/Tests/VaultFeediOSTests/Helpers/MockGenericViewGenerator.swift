import Foundation
import SwiftUI
import VaultCore
import VaultFeediOS

final class MockGenericViewGenerator: VaultItemPreviewViewGenerator {
    typealias PreviewItem = VaultItem

    func makeVaultPreviewView(id _: UUID, item _: PreviewItem, behaviour _: VaultItemViewBehaviour) -> some View {
        ZStack {
            Color.blue
            Text("Code")
                .foregroundStyle(.white)
        }
        .frame(minHeight: 100)
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    func didAppear() {
        // noop
    }
}
