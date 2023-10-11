import Foundation
import SwiftUI
import VaultFeed

public protocol HOTPPreviewViewFactory {
    associatedtype HOTPView: View
    func makeHOTPView(
        viewModel: CodePreviewViewModel,
        incrementer: CodeIncrementerViewModel,
        behaviour: VaultItemViewBehaviour
    )
        -> HOTPView
}

public struct RealHOTPPreviewViewFactory: HOTPPreviewViewFactory {
    public init() {}
    public func makeHOTPView(
        viewModel: CodePreviewViewModel,
        incrementer: CodeIncrementerViewModel,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        HOTPCodePreviewView(
            buttonView: CodeButtonView(viewModel: incrementer),
            previewViewModel: viewModel,
            behaviour: behaviour
        )
    }
}
