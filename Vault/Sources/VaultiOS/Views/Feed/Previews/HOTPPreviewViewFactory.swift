import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: HOTPView = AnyView)
@MainActor
protocol HOTPPreviewViewFactory {
    associatedtype HOTPView: View
    func makeHOTPView(
        viewModel: OTPCodePreviewViewModel,
        incrementer: OTPCodeIncrementerViewModel,
        behaviour: VaultItemViewBehaviour
    )
        -> HOTPView
}

struct HOTPPreviewViewFactoryImpl: HOTPPreviewViewFactory {
    init() {}
    func makeHOTPView(
        viewModel: OTPCodePreviewViewModel,
        incrementer: OTPCodeIncrementerViewModel,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        HOTPCodePreviewView(
            buttonView: OTPCodeButtonView(viewModel: incrementer),
            previewViewModel: viewModel,
            behaviour: behaviour
        )
    }
}
