import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailKillphraseEditView: View {
    var title: String
    var description: String
    var hiddenWithKillphraseTitle: String
    @State private var killphraseIsEnabled: Bool = false
    @Binding var killphrase: String

    init(title: String, description: String, hiddenWithKillphraseTitle: String, killphrase: Binding<String>) {
        self.title = title
        self.description = description
        self.hiddenWithKillphraseTitle = hiddenWithKillphraseTitle
        killphraseIsEnabled = killphrase.wrappedValue.isNotEmpty
        _killphrase = killphrase
    }

    var body: some View {
        Form {
            titleSection
            if killphraseIsEnabled {
                optionSection
            }
        }
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(systemIcon: "delete.backward.fill", title: title, subtitle: description)
                .padding()
                .containerRelativeFrame(.horizontal)

            Toggle(isOn: $killphraseIsEnabled) {
                FormRow(
                    image: Image(systemName: killphraseIsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill"),
                    color: killphraseIsEnabled ? .green : .secondary,
                    style: .standard
                ) {
                    Text("Enable killphrase")
                        .font(.body)
                }
            }
        }
    }

    private var optionSection: some View {
        Section {
            FormRow(image: Image(systemName: "textformat"), color: .secondary, style: .standard) {
                TextField("Enter killphrase...", text: $killphrase)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .textInputAutocapitalization(.never)
            }
        } footer: {
            Text(hiddenWithKillphraseTitle)
        }
    }
}

#Preview {
    VaultDetailKillphraseEditView(
        title: "Test",
        description: "This is a test",
        hiddenWithKillphraseTitle: "This will be killed",
        killphrase: .constant("x")
    )
}
