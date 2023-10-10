import Foundation
import OTPCore
import OTPFeediOS
import SwiftUI

final class MockGenericViewGenerator: VaultItemPreviewViewGenerator {
    typealias VaultItem = GenericOTPAuthCode

    func makeVaultPreviewView(id _: UUID, code _: VaultItem, behaviour _: VaultItemViewBehaviour) -> some View {
        ZStack {
            Color.blue
            Text("Code")
                .foregroundStyle(.white)
        }
        .frame(minHeight: 100)
    }

    func scenePhaseDidChange(to _: ScenePhase) {
        // noop
    }

    func didAppear() {
        // noop
    }
}
