import Foundation
import OTPCore
import OTPFeed
import SwiftUI

public struct GenericOTPViewGenerator<BodyView: View>: OTPViewGenerator {
    public typealias Code = GenericOTPAuthCode

    private let view: (UUID, GenericOTPAuthCode, Bool) -> BodyView

    public init(@ViewBuilder view: @escaping (UUID, GenericOTPAuthCode, Bool) -> BodyView) {
        self.view = view
    }

    @ViewBuilder
    public func makeOTPView(id: UUID, code: Code, isEditing: Bool) -> some View {
        view(id, code, isEditing)
    }
}
