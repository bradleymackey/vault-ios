import Foundation
import SwiftUI
import VaultCore
import VaultFeed

public struct GenericVaultItemPreviewViewGenerator<
    TOTP: VaultItemPreviewViewGenerator,
    HOTP: VaultItemPreviewViewGenerator
>: VaultItemPreviewViewGenerator
    where TOTP.VaultItem == TOTPAuthCode,
    HOTP.VaultItem == HOTPAuthCode
{
    public typealias VaultItem = GenericOTPAuthCode
    private let totpGenerator: TOTP
    private let hotpGenerator: HOTP

    public init(totpGenerator: TOTP, hotpGenerator: HOTP) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
    }

    @ViewBuilder
    public func makeVaultPreviewView(id: UUID, code: VaultItem, behaviour: VaultItemViewBehaviour) -> some View {
        switch code.type {
        case let .totp(period):
            totpGenerator.makeVaultPreviewView(
                id: id,
                code: .init(period: period, data: code.data),
                behaviour: behaviour
            )
        case let .hotp(counter):
            hotpGenerator.makeVaultPreviewView(
                id: id,
                code: .init(counter: counter, data: code.data),
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
