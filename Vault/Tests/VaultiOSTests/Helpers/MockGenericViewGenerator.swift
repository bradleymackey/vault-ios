import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultiOS

final class MockGenericViewGenerator: VaultItemPreviewViewGenerator {
    typealias PreviewItem = StoredVaultItem.Payload

    func makeVaultPreviewView(
        item _: PreviewItem,
        metadata _: StoredVaultItem.Metadata,
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
