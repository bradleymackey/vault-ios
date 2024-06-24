import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultiOS

final class MockGenericViewGenerator: VaultItemPreviewViewGenerator {
    typealias PreviewItem = VaultItem.Payload

    func makeVaultPreviewView(
        item _: PreviewItem,
        metadata _: VaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
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
