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
            optionSection
        }
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(systemIcon: "eye.fill", title: title, subtitle: description)
                .padding()
                .containerRelativeFrame(.horizontal)
        }
    }

    private var optionSection: some View {
        Section {
            Toggle(isOn: $viewConfig.isEnabled) {
                FormRow(
                    image: Image(systemName: viewConfig.isEnabled ? "eye.slash" : "eye.fill"),
                    color: viewConfig.isEnabled ? .red : .green,
                    style: .standard
                ) {
                    Text("Hide with passphrase")
                        .font(.body)
                }
            }
            if viewConfig.isEnabled {
                FormRow(image: Image(systemName: "entry.lever.keypad.fill"), color: .blue, style: .standard) {
                    TextField("Enter passphrase...", text: $passphrase)
                        .keyboardType(.default)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .textInputAutocapitalization(.never)
                }
            }
        } footer: {
            if viewConfig.isEnabled {
                Text(hiddenWithPassphraseTitle)
            }
        }
    }
}
