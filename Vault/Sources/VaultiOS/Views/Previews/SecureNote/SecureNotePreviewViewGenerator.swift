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

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    func didAppear() {
        // noop
    }
}

extension SecureNotePreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        .openItemDetail(id)
    }

    func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> VaultTextCopyAction? {
        nil
    }
}
