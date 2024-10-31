import Foundation
import SwiftUI
import VaultFeed
import VaultiOS

public struct VaultAutofillView<Generator: VaultItemPreviewViewGenerator<VaultItem.Payload>>: View {
    @State private var viewModel: VaultAutofillViewModel
    var generator: Generator

    public init(
        viewModel: VaultAutofillViewModel,
        generator: Generator
    ) {
        self.viewModel = viewModel
        self.generator = generator
    }

    public var body: some View {
        Group {
            switch viewModel.feature {
            case .setupConfiguration:
                VaultAutofillConfigurationView(viewModel: .init(dismissSubject: viewModel.configurationDismissSubject))
            case .showAllCodesSelector:
                NavigationStack {
                    VaultAutofillCodeSelectorView(localSettings: viewModel.localSettings, viewGenerator: generator)
                }
            case let .unimplemented(name):
                Text("Unimplemented \(name)")
            case nil:
                ProgressView()
            }
        }
    }
}
