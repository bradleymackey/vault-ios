import Foundation
import SwiftUI

public struct VaultAutofillEntrypointView: View {
    @State private var viewModel: VaultAutofillEntrypointViewModel
    public init(viewModel: VaultAutofillEntrypointViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.feature {
            case .setupConfiguration:
                VaultAutofillConfigurationView(viewModel: .init(dismissSubject: viewModel.configurationDismissSubject))
            case nil:
                ProgressView()
            }
        }
    }
}
