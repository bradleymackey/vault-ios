import Foundation
import OTPCore
import OTPFeediOS
import SwiftUI

final class MockGenericViewGenerator: OTPViewGenerator {
    typealias Code = GenericOTPAuthCode

    func makeOTPView(id _: UUID, code _: Code, behaviour _: OTPViewBehaviour) -> some View {
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
