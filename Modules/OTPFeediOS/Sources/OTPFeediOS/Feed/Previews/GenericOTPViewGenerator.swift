import Foundation
import OTPCore
import OTPFeed
import SwiftUI

public struct GenericOTPViewGenerator<TOTP: OTPViewGenerator, HOTP: OTPViewGenerator>: OTPViewGenerator
    where TOTP.Code == TOTPAuthCode,
    HOTP.Code == HOTPAuthCode
{
    public typealias Code = GenericOTPAuthCode
    private let totpGenerator: TOTP
    private let hotpGenerator: HOTP

    public init(totpGenerator: TOTP, hotpGenerator: HOTP) {
        self.totpGenerator = totpGenerator
        self.hotpGenerator = hotpGenerator
    }

    @ViewBuilder
    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour) -> some View {
        switch code.type {
        case let .totp(period):
            totpGenerator.makeOTPView(id: id, code: .init(period: period, data: code.data), behaviour: behaviour)
        case let .hotp(counter):
            hotpGenerator.makeOTPView(id: id, code: .init(counter: counter, data: code.data), behaviour: behaviour)
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

extension GenericOTPViewGenerator: OTPCodeProvider where TOTP: OTPCodeProvider, HOTP: OTPCodeProvider {
    public func currentVisibleCode(id: UUID) -> String? {
        totpGenerator.currentVisibleCode(id: id) ?? hotpGenerator.currentVisibleCode(id: id)
    }
}
