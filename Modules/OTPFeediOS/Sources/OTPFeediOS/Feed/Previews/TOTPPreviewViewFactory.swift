import Foundation
import OTPFeed
import SwiftUI

public protocol TOTPPreviewViewFactory {
    associatedtype TOTPView: View
    func makeTOTPView(viewModel: CodePreviewViewModel, periodState: CodeTimerPeriodState, behaviour: OTPViewBehaviour?)
        -> TOTPView
}

public struct RealTOTPPreviewViewFactory: TOTPPreviewViewFactory {
    public init() {}
    public func makeTOTPView(
        viewModel: CodePreviewViewModel,
        periodState: CodeTimerPeriodState,
        behaviour: OTPViewBehaviour?
    ) -> some View {
        TOTPCodePreviewView(
            previewViewModel: viewModel,
            timerView: CodeTimerHorizontalBarView(
                timerState: periodState,
                color: .blue
            ),
            behaviour: behaviour
        )
    }
}
