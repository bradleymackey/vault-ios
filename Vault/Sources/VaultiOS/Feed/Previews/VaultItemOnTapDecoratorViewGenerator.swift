import Foundation
import SwiftUI
import VaultFeed

public struct VaultItemOnTapDecoratorViewGenerator<
    Generator: VaultItemPreviewViewGenerator
>: VaultItemPreviewViewGenerator {
    public typealias PreviewItem = Generator.PreviewItem
    public let generator: Generator
    public let onTap: (UUID) -> Void

    public init(generator: Generator, onTap: @escaping (UUID) -> Void) {
        self.generator = generator
        self.onTap = onTap
    }

    public func makeVaultPreviewView(
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

    public func scenePhaseDidChange(to scene: ScenePhase) {
        generator.scenePhaseDidChange(to: scene)
    }

    public func didAppear() {
        generator.didAppear()
    }
}

extension VaultItemOnTapDecoratorViewGenerator: VaultItemPreviewActionHandler
    where Generator: VaultItemPreviewActionHandler
{
    public func previewActionForVaultItem(id: UUID) -> VaultItemPreviewAction? {
        generator.previewActionForVaultItem(id: id)
    }
}
