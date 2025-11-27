import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: TOTPView = AnyView)
@MainActor
public protocol TOTPPreviewViewFactory {
    associatedtype TOTPView: View
    func makeTOTPView(
        viewModel: OTPCodePreviewViewModel,
        periodState: OTPCodeTimerPeriodState,
        updater: any OTPCodeTimerUpdater,
        behaviour: VaultItemViewBehaviour,
    )
        -> TOTPView
}

public struct TOTPPreviewViewFactoryImpl: TOTPPreviewViewFactory {
    public func makeTOTPView(
        viewModel: OTPCodePreviewViewModel,
        periodState: OTPCodeTimerPeriodState,
        updater _: any OTPCodeTimerUpdater,
        behaviour: VaultItemViewBehaviour,
    ) -> some View {
        TOTPCodePreviewView(
            previewViewModel: viewModel,
            timerView: CodeTimerHorizontalBarView(
                timerState: periodState,
                color: .blue,
            ),
            behaviour: behaviour,
        )
    }
}
