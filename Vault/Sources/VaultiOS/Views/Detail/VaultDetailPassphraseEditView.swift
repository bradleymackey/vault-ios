import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailPassphraseEditView: View {
    var title: String
    var description: String
    var hiddenWithPassphraseTitle: String
    @Binding var viewConfig: VaultItemViewConfiguration
    @Binding var passphrase: String

    var body: some View {
        Form {
            titleSection
            if viewConfig.isEnabled {
                optionSection
            }
        }
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(
                systemIcon: viewConfig.isEnabled ? "eye.slash" : "eye.fill",
                title: title,
                subtitle: description
            )
            .padding()
            .containerRelativeFrame(.horizontal)

            Toggle(isOn: $viewConfig.isEnabled) {
                FormRow(
                    image: Image(systemName: viewConfig.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill"),
                    color: viewConfig.isEnabled ? .green : .secondary,
                    style: .standard
                ) {
                    Text("Hide with passphrase")
                        .font(.body)
                }
            }
        }
    }

    private var optionSection: some View {
        Section {
            FormRow(image: Image(systemName: "textformat"), color: .secondary, style: .standard) {
                TextField("Enter passphrase...", text: $passphrase)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .textInputAutocapitalization(.never)
            }
        } footer: {
            Text(hiddenWithPassphraseTitle)
        }
    }
}

#Preview {
    VaultDetailPassphraseEditView(
        title: "Test",
        description: "Test",
        hiddenWithPassphraseTitle: "nice",
        viewConfig: .constant(.requiresSearchPassphrase),
        passphrase: .constant("nice")
    )
}
