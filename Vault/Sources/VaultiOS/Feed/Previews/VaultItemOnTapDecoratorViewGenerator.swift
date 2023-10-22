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
        metadata: StoredVaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        Button {
            onTap(metadata.id)
        } label: {
            generator.makeVaultPreviewView(item: item, metadata: metadata, behaviour: behaviour)
                .modifier(OTPCardViewModifier())
        }
    }

    public func scenePhaseDidChange(to scene: ScenePhase) {
        generator.scenePhaseDidChange(to: scene)
    }

    public func didAppear() {
        generator.didAppear()
    }
}

extension VaultItemOnTapDecoratorViewGenerator: VaultItemCopyTextProvider where Generator: VaultItemCopyTextProvider {
    public func currentCopyableText(id: UUID) -> String? {
        generator.currentCopyableText(id: id)
    }
}
