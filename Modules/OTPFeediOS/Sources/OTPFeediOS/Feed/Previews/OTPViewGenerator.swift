import Foundation
import OTPCore
import SwiftUI

@MainActor
public protocol OTPViewGenerator {
    associatedtype Code
    associatedtype CodeView: View
    func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour) -> CodeView
    func scenePhaseDidChange(to scene: ScenePhase)
    func didAppear()
}

public protocol OTPCodeProvider {
    func currentVisibleCode(id: UUID) -> String?
}
