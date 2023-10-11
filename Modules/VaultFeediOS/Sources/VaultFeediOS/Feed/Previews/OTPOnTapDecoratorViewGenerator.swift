import Foundation
import SwiftUI
import VaultFeed

public struct OTPOnTapDecoratorViewGenerator<Generator: VaultItemPreviewViewGenerator>: VaultItemPreviewViewGenerator {
    public typealias PreviewItem = Generator.PreviewItem
    public let generator: Generator
    public let onTap: (UUID) -> Void

    public init(generator: Generator, onTap: @escaping (UUID) -> Void) {
        self.generator = generator
        self.onTap = onTap
    }

    public func makeVaultPreviewView(id: UUID, item: PreviewItem, behaviour: VaultItemViewBehaviour) -> some View {
        Button {
            onTap(id)
        } label: {
            generator.makeVaultPreviewView(id: id, item: item, behaviour: behaviour)
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

extension OTPOnTapDecoratorViewGenerator: VaultItemCopyTextProvider where Generator: VaultItemCopyTextProvider {
    public func currentCopyableText(id: UUID) -> String? {
        generator.currentCopyableText(id: id)
    }
}
