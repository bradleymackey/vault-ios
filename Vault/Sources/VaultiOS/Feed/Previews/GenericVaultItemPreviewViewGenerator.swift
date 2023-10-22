import Foundation
import SwiftUI
import VaultCore
import VaultFeed

public struct GenericVaultItemPreviewViewGenerator<
    TOTP: VaultItemPreviewViewGenerator,
    HOTP: VaultItemPreviewViewGenerator,
    Note: VaultItemPreviewViewGenerator
>: VaultItemPreviewViewGenerator
    where TOTP.PreviewItem == TOTPAuthCode,
    HOTP.PreviewItem == HOTPAuthCode,
    Note.PreviewItem == SecureNote
{
    public typealias PreviewItem = VaultItem
    private let totpGenerator: TOTP
    private let hotpGenerator: HOTP
    private let noteGenerator: Note
    private let allGenerators: [any VaultItemPreviewViewGenerator]

    public init(totpGenerator: TOTP, hotpGenerator: HOTP, noteGenerator: Note) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.noteGenerator = noteGenerator
        allGenerators = [totpGenerator, hotpGenerator, noteGenerator]
    }

    @ViewBuilder
    public func makeVaultPreviewView(
        item: PreviewItem,
        metadata: StoredVaultItem.Metadata,
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

    public func scenePhaseDidChange(to scenePhase: ScenePhase) {
        for generator in allGenerators {
            generator.scenePhaseDidChange(to: scenePhase)
        }
    }

    public func didAppear() {
        for generator in allGenerators {
            generator.didAppear()
        }
    }
}

extension GenericVaultItemPreviewViewGenerator: VaultItemPreviewActionHandler {
    public func previewActionForVaultItem(id: UUID) -> VaultItemPreviewAction? {
        for generator in allGenerators {
            if let actionHandler = generator as? any VaultItemPreviewActionHandler,
               let action = actionHandler.previewActionForVaultItem(id: id)
            {
                return action
            }
        }
        return nil
    }
}
