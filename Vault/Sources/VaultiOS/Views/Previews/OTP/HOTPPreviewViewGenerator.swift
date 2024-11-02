import CryptoEngine
import SwiftUI
import VaultFeed

@MainActor
final class HOTPPreviewViewGenerator<Factory: HOTPPreviewViewFactory>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = HOTPAuthCode

    private let viewFactory: Factory
    private let repository: any HOTPPreviewViewRepository

    init(viewFactory: Factory, repository: any HOTPPreviewViewRepository) {
        self.viewFactory = viewFactory
        self.repository = repository
    }

    func makeVaultPreviewView(
        item: PreviewItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        viewFactory.makeHOTPView(
            viewModel: repository.previewViewModel(metadata: metadata, code: item),
            incrementer: repository.incrementerViewModel(id: metadata.id, code: item),
            behaviour: behaviour
        )
    }

    func clearViewCache() async {
        await repository.vaultItemCacheClearAll()
    }

    func scenePhaseDidChange(to scene: ScenePhase) {
        switch scene {
        case .active:
            repository.unobfuscateForPrivacy()
        case .inactive:
            repository.obfuscateForPrivacy()
        case .background:
            repository.expireAll()
        @unknown default:
            break
        }
    }

    func didAppear() {
        // noop
    }
}
