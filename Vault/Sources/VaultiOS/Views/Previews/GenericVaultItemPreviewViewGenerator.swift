import Foundation
import SwiftUI
import VaultFeed

struct GenericVaultItemPreviewViewGenerator<
    TOTP: VaultItemPreviewViewGenerator<TOTPAuthCode>,
    HOTP: VaultItemPreviewViewGenerator<HOTPAuthCode>,
    Note: VaultItemPreviewViewGenerator<SecureNote>,
    Encrypted: VaultItemPreviewViewGenerator<EncryptedItem>
>: VaultItemPreviewViewGenerator {
    typealias PreviewItem = VaultItem.Payload
    private let totpGenerator: TOTP
    private let hotpGenerator: HOTP
    private let noteGenerator: Note
    private let encryptedGenerator: Encrypted

    init(totpGenerator: TOTP, hotpGenerator: HOTP, noteGenerator: Note, encryptedGenerator: Encrypted) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
        self.noteGenerator = noteGenerator
        self.encryptedGenerator = encryptedGenerator
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
        case let .encryptedItem(data):
            encryptedGenerator.makeVaultPreviewView(item: data, metadata: metadata, behaviour: behaviour)
        }
    }

    func clearViewCache() async {
        await totpGenerator.clearViewCache()
        await hotpGenerator.clearViewCache()
        await noteGenerator.clearViewCache()
        await encryptedGenerator.clearViewCache()
    }

    func scenePhaseDidChange(to scenePhase: ScenePhase) {
        totpGenerator.scenePhaseDidChange(to: scenePhase)
        hotpGenerator.scenePhaseDidChange(to: scenePhase)
        noteGenerator.scenePhaseDidChange(to: scenePhase)
        encryptedGenerator.scenePhaseDidChange(to: scenePhase)
    }

    func didAppear() {
        totpGenerator.didAppear()
        hotpGenerator.didAppear()
        noteGenerator.didAppear()
        encryptedGenerator.didAppear()
    }
}
