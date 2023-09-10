import Foundation
import OTPFeed
import SwiftUI

public struct OTPOnTapDecoratorViewGenerator<Generator: OTPViewGenerator>: OTPViewGenerator {
    public typealias Code = Generator.Code
    public let generator: Generator
    public let onTap: (UUID) -> Void

    public init(generator: Generator, onTap: @escaping (UUID) -> Void) {
        self.generator = generator
        self.onTap = onTap
    }

    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour) -> some View {
        Button {
            onTap(id)
        } label: {
            generator.makeOTPView(id: id, code: code, behaviour: behaviour)
                .modifier(OTPCardViewModifier())
        }
    }

    public func scenePhaseDidChange(to scene: ScenePhase) {
        generator.scenePhaseDidChange(to: scene)
    }

    public func didAppear() {
        generator.didAppear()
    }
}

extension OTPOnTapDecoratorViewGenerator: OTPCodeProvider where Generator: OTPCodeProvider {
    public func currentVisibleCode(id: UUID) -> String? {
        generator.currentVisibleCode(id: id)
    }
}
