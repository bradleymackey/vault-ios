import Foundation
import FoundationExtensions
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
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        let viewModel = SecureNotePreviewViewModel(
            title: item.title,
            description: metadata.userDescription,
            color: metadata.color ?? .default
        )
        return viewFactory.makeSecureNoteView(viewModel: viewModel, behaviour: behaviour)
    }

    public func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    public func didAppear() {
        // noop
    }
}

extension SecureNotePreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    public func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        .openItemDetail(id)
    }

    public func textToCopyForVaultItem(id _: Identifier<VaultItem>) -> String? {
        "TODO"
    }
}
