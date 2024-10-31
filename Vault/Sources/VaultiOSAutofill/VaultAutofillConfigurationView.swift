import Foundation
import SwiftUI

public struct VaultAutofillConfigurationView: View {
    @State private var viewModel: VaultAutofillConfigurationViewModel
    public init(viewModel: VaultAutofillConfigurationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 8) {
                Text("Vault Autofill")
                    .font(.largeTitle.bold())
                Text("Only 2FA codes must be visible to autofill.")
                Text("This means locked, hidden or other protected codes will not be offered for autofilling.")
                Button {
//                    dismiss()
                } label: {
                    Text("OK")
                }
            }
        }
    }
}
