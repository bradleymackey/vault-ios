import Foundation
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
public final class SecureNotePreviewViewGenerator<Factory: SecureNotePreviewViewFactory>: VaultItemPreviewViewGenerator {
    public typealias PreviewItem = SecureNote

    private let viewFactory: Factory

    public init(
        viewFactory: Factory
    ) {
        self.viewFactory = viewFactory
    }

    public func makeVaultPreviewView(
        item: SecureNote,
        metadata: StoredVaultItem.Metadata,
        behaviour _: VaultItemViewBehaviour
    ) -> some View {
        let viewModel = SecureNotePreviewViewModel(
            title: item.title,
            description: metadata.userDescription
        )
        return viewFactory.makeSecureNoteView(viewModel: viewModel)
    }

    public func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    public func didAppear() {
        // noop
    }
}

extension SecureNotePreviewViewGenerator: VaultItemPreviewActionHandler {
    public func previewActionForVaultItem(id: UUID) -> VaultItemPreviewAction? {
        .openItemDetail(id)
    }
}
