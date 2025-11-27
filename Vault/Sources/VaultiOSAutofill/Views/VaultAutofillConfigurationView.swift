import Foundation
import SwiftUI
import VaultiOS

struct VaultAutofillConfigurationView: View {
    @State private var viewModel: VaultAutofillConfigurationViewModel
    init(viewModel: VaultAutofillConfigurationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            container
                .padding(.vertical, 16)
                .padding(24)
                .containerRelativeFrame([.horizontal, .vertical])
        }
        .containerRelativeFrame([.horizontal, .vertical])
    }

    private var container: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "character.textbox")
                    .font(.largeTitle.bold())
                Text("Vault Autofill")
                    .font(.largeTitle.bold())
            }

            VStack(alignment: .center, spacing: 8) {
                Text("Autofill for your items is now enabled.")
                Text(
                    "To autofill in a text field, hold down on the text field, select 'Autofill' followed by 'Passwords'",
                )
            }
            .font(.body)

            VStack(alignment: .center, spacing: 8) {
                Text(
                    "Due to a bug in the latest release of iOS, OTP codes may not automatically offer to autofill currently. This feature will be added as soon as possible.",
                )
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button {
                viewModel.dismiss()
            } label: {
                Text("Understood")
                    .font(.headline)
            }
            .modifier(ProminentButtonModifier())
        }
        .multilineTextAlignment(.center)
    }
}
