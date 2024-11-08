import Foundation
import SwiftUI
import VaultFeed

@MainActor
final class EncryptedItemPreviewViewGenerator<Factory: EncryptedItemPreviewViewFactory>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = EncryptedItem

    private let viewFactory: Factory

    init(viewFactory: Factory) {
        self.viewFactory = viewFactory
    }

    func makeVaultPreviewView(
        item: EncryptedItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        let viewModel = EncryptedItemPreviewViewModel(
            title: item.title,
            color: metadata.color ?? .default
        )
        return viewFactory.makeEncryptedItemView(viewModel: viewModel, behaviour: behaviour)
    }

    func clearViewCache() async {
        // noop, cache is not used for encrypted item preview views atm
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop, nothing to do at the generator-level at the moment
    }

    func didAppear() {
        // noop, nothing to do at the generator-level at the moment
    }
}
