import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: HOTPView = AnyView)
public protocol HOTPPreviewViewFactory {
    associatedtype HOTPView: View
    func makeHOTPView(
        viewModel: OTPCodePreviewViewModel,
        incrementer: OTPCodeIncrementerViewModel,
        behaviour: VaultItemViewBehaviour
    )
        -> HOTPView
}

public struct HOTPPreviewViewFactoryImpl: HOTPPreviewViewFactory {
    public init() {}
    public func makeHOTPView(
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
