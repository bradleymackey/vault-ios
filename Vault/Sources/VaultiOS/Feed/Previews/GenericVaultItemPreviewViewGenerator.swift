import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

public typealias GeneratorWithActions = VaultItemCopyActionHandler & VaultItemPreviewActionHandler &
    VaultItemPreviewViewGenerator

public struct GenericVaultItemPreviewViewGenerator<
    TOTP: GeneratorWithActions,
    HOTP: GeneratorWithActions,
    Note: GeneratorWithActions
>: VaultItemPreviewViewGenerator
    where TOTP.PreviewItem == TOTPAuthCode,
    HOTP.PreviewItem == HOTPAuthCode,
    Note.PreviewItem == SecureNote
{
    public typealias PreviewItem = VaultItem.Payload
    private let totpGenerator: TOTP
    private let hotpGenerator: HOTP
    private let noteGenerator: Note
    private let allGenerators: [any GeneratorWithActions]

    public init(totpGenerator: TOTP, hotpGenerator: HOTP, noteGenerator: Note) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.noteGenerator = noteGenerator
        allGenerators = [totpGenerator, hotpGenerator, noteGenerator]
    }

    @ViewBuilder
    public func makeVaultPreviewView(
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

extension GenericVaultItemPreviewViewGenerator: VaultItemPreviewActionHandler, VaultItemCopyActionHandler {
    public func textToCopyForVaultItem(id: Identifier<VaultItem>) -> String? {
        for generator in allGenerators {
            if let text = generator.textToCopyForVaultItem(id: id) {
                return text
            }
        }
        return nil
    }

    public func previewActionForVaultItem(id: Identifier<VaultItem>) -> VaultItemPreviewAction? {
        for generator in allGenerators {
            if let action = generator.previewActionForVaultItem(id: id) {
                return action
            }
        }
        return nil
    }
}
