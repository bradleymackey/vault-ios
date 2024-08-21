import Foundation
import FoundationExtensions
import SwiftUI
import VaultFeed

struct VaultItemOnTapDecoratorViewGenerator<
    Generator: VaultItemPreviewViewGenerator
>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = Generator.PreviewItem
    let generator: Generator
    let onTap: (Identifier<VaultItem>) -> Void

    init(generator: Generator, onTap: @escaping (Identifier<VaultItem>) -> Void) {
        self.generator = generator
        self.onTap = onTap
    }

    func makeVaultPreviewView(
        item: PreviewItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        Button {
            onTap(metadata.id)
        } label: {
            generator.makeVaultPreviewView(item: item, metadata: metadata, behaviour: behaviour)
        }
    }

    func scenePhaseDidChange(to scene: ScenePhase) {
        generator.scenePhaseDidChange(to: scene)
    }

    func didAppear() {
        generator.didAppear()
    }
}

extension VaultItemOnTapDecoratorViewGenerator: VaultItemPreviewActionHandler
    where Generator: VaultItemPreviewActionHandler
{
    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        generator.previewActionForVaultItem(id: id)
    }
}
