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

    public init(totpGenerator: TOTP, hotpGenerator: HOTP, noteGenerator: Note) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.noteGenerator = noteGenerator
    }

    @ViewBuilder
    public func makeVaultPreviewView(id: UUID, item: PreviewItem, behaviour: VaultItemViewBehaviour) -> some View {
        switch item {
        case let .otpCode(otpCode):
            switch otpCode.type {
            case let .totp(period):
                totpGenerator.makeVaultPreviewView(
                    id: id,
                    item: .init(period: period, data: otpCode.data),
                    behaviour: behaviour
                )
            case let .hotp(counter):
                hotpGenerator.makeVaultPreviewView(
                    id: id,
                    item: .init(counter: counter, data: otpCode.data),
                    behaviour: behaviour
                )
            }
        case let .secureNote(secureNote):
            noteGenerator.makeVaultPreviewView(
                id: id,
                item: secureNote,
                behaviour: behaviour
            )
        }
    }

    public func scenePhaseDidChange(to scenePhase: ScenePhase) {
        hotpGenerator.scenePhaseDidChange(to: scenePhase)
        totpGenerator.scenePhaseDidChange(to: scenePhase)
    }

    public func didAppear() {
        hotpGenerator.didAppear()
        totpGenerator.didAppear()
    }
}

extension GenericVaultItemPreviewViewGenerator: VaultItemCopyTextProvider where TOTP: VaultItemCopyTextProvider,
    HOTP: VaultItemCopyTextProvider
{
    public func currentCopyableText(id: UUID) -> String? {
        totpGenerator.currentCopyableText(id: id) ?? hotpGenerator.currentCopyableText(id: id)
    }
}
