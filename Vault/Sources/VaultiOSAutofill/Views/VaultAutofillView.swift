import Foundation
import SwiftUI

public struct VaultAutofillView: View {
    @State private var viewModel: VaultAutofillViewModel
    public init(viewModel: VaultAutofillViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.feature {
            case .setupConfiguration:
                VaultAutofillConfigurationView(viewModel: .init(dismissSubject: viewModel.configurationDismissSubject))
            case .showCodeSelector:
                ProgressView()
            case nil:
                ProgressView()
            }
        }
    }
}
