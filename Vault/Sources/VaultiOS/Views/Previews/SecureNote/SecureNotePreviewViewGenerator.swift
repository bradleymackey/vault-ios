import Foundation
import SwiftUI
import VaultFeed

@MainActor
final class SecureNotePreviewViewGenerator<Factory: SecureNotePreviewViewFactory>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = SecureNote

    private let viewFactory: Factory

    init(
        viewFactory: Factory
    ) {
        self.viewFactory = viewFactory
    }

    func makeVaultPreviewView(
        item: SecureNote,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        let viewModel = SecureNotePreviewViewModel(
            title: item.title,
            description: metadata.userDescription,
            color: metadata.color ?? .default,
            isLocked: metadata.lockState.isLocked,
            textFormat: item.format
        )
        return viewFactory.makeSecureNoteView(viewModel: viewModel, behaviour: behaviour)
    }

    func clearViewCache() async {
        // noop, cache is not used for secure note preview views atm
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop, nothing to do at the generator-level at the moment
    }

    func didAppear() {
        // noop, nothing to do at the generator-level at the moment
    }
}
