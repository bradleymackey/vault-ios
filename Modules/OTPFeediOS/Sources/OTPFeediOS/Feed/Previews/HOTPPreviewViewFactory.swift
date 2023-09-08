import Foundation
import OTPFeed
import SwiftUI

public protocol HOTPPreviewViewFactory {
    associatedtype HOTPView: View
    func makeHOTPView(
        viewModel: CodePreviewViewModel,
        incrementer: CodeIncrementerViewModel,
        behaviour: OTPViewBehaviour
    )
        -> HOTPView
}

public struct RealHOTPPreviewViewFactory: HOTPPreviewViewFactory {
    public init() {}
    public func makeHOTPView(
        viewModel: CodePreviewViewModel,
        incrementer: CodeIncrementerViewModel,
        behaviour: OTPViewBehaviour
    ) -> some View {
        HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: incrementer),
            previewViewModel: viewModel,
            behaviour: behaviour
        )
    }
}
