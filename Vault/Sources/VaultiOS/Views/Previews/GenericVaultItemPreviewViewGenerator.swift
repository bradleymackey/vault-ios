import Foundation
import SwiftUI
import VaultFeed

struct GenericVaultItemPreviewViewGenerator<
    TOTP: ActionableVaultItemPreviewViewGenerator<TOTPAuthCode>,
    HOTP: ActionableVaultItemPreviewViewGenerator<HOTPAuthCode>,
    Note: ActionableVaultItemPreviewViewGenerator<SecureNote>
>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = VaultItem.Payload
    private let totpGenerator: TOTP
    private let hotpGenerator: HOTP
    private let noteGenerator: Note
    private let sceneResponders: [any VaultItemPreviewSceneResponder]
    private let previewActionHandlers: [any VaultItemPreviewActionHandler]
    private let copyActionHandlers: [any VaultItemCopyActionHandler]

    init(totpGenerator: TOTP, hotpGenerator: HOTP, noteGenerator: Note) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.noteGenerator = noteGenerator
        sceneResponders = [totpGenerator, hotpGenerator, noteGenerator]
        previewActionHandlers = [totpGenerator, hotpGenerator, noteGenerator]
        copyActionHandlers = [totpGenerator, hotpGenerator, noteGenerator]
    }

    @ViewBuilder
    func makeVaultPreviewView(
        item: PreviewItem,
        metadata: VaultItem.Metadata,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        switch item {
        case let .otpCode(otpCode):
            switch otpCode.type {
            case let .totp(period):
                totpGenerator.makeVaultPreviewView(
                    item: .init(period: period, data: otpCode.data),
                    metadata: metadata,
                    behaviour: behaviour
                )
            case let .hotp(counter):
                hotpGenerator.makeVaultPreviewView(
                    item: .init(counter: counter, data: otpCode.data),
                    metadata: metadata,
                    behaviour: behaviour
                )
            }
        case let .secureNote(secureNote):
            noteGenerator.makeVaultPreviewView(
                item: secureNote,
                metadata: metadata,
                behaviour: behaviour
            )
        }
    }

    func scenePhaseDidChange(to scenePhase: ScenePhase) {
        for sceneResponder in sceneResponders {
            sceneResponder.scenePhaseDidChange(to: scenePhase)
        }
    }

    func didAppear() {
        for sceneResponder in sceneResponders {
            sceneResponder.didAppear()
        }
    }
}

extension GenericVaultItemPreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    func textToCopyForVaultItem(id: Identifier<VaultItem>) -> VaultTextCopyAction? {
        for handler in copyActionHandlers {
            if let copyAction = handler.textToCopyForVaultItem(id: id) {
                return copyAction
            }
        }
        return nil
    }

    func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        for handler in previewActionHandlers {
            if let action = handler.previewActionForVaultItem(id: id) {
                return action
            }
        }
        return nil
    }
}
