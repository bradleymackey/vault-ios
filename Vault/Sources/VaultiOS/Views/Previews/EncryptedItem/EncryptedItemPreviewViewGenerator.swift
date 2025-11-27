import Foundation
import SwiftUI
import VaultFeed

@MainActor
public final class EncryptedItemPreviewViewGenerator<
    Factory: EncryptedItemPreviewViewFactory,
>: VaultItemPreviewViewGenerator {
    public typealias PreviewItem = EncryptedItem

    private let viewFactory: Factory

    init(viewFactory: Factory) {
        self.viewFactory = viewFactory
    }

    public func makeVaultPreviewView(
        item: EncryptedItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour,
    ) -> some View {
        let viewModel = EncryptedItemPreviewViewModel(
            title: item.title,
            color: metadata.color ?? .default,
        )
        return viewFactory.makeEncryptedItemView(viewModel: viewModel, behaviour: behaviour)
    }

    public func clearViewCache() async {
        // noop, cache is not used for encrypted item preview views atm
    }

    public func scenePhaseDidChange(to _: ScenePhase) {
        // noop, nothing to do at the generator-level at the moment
    }

    public func didAppear() {
        // noop, nothing to do at the generator-level at the moment
    }
}
