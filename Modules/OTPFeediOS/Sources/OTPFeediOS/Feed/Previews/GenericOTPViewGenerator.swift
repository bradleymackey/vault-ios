import Foundation
import OTPCore
import OTPFeed
import SwiftUI

public struct GenericOTPViewGenerator<BodyView: View>: OTPViewGenerator {
    public typealias Code = GenericOTPAuthCode

    private let view: (UUID, GenericOTPAuthCode, OTPViewBehaviour?) -> BodyView

    public init(@ViewBuilder view: @escaping (UUID, GenericOTPAuthCode, OTPViewBehaviour?) -> BodyView) {
        self.view = view
    }

    @ViewBuilder
    public func makeOTPView(id: UUID, code: Code, behaviour: OTPViewBehaviour?) -> some View {
        view(id, code, behaviour)
    }
}
