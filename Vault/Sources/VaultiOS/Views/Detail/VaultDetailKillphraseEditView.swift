import Foundation
import SwiftUI
import VaultFeed

struct VaultDetailKillphraseEditView: View {
    var title: String
    var description: String
    var hiddenWithKillphraseTitle: String
    @State private var killphraseIsEnabled: Bool = false
    @Binding var killphrase: String

    init(
        title: String,
        description: String,
        hiddenWithKillphraseTitle: String,
        killphrase: Binding<String>
    ) {
        self.title = title
        self.description = description
        self.hiddenWithKillphraseTitle = hiddenWithKillphraseTitle
        killphraseIsEnabled = killphrase.wrappedValue.isNotEmpty
        _killphrase = killphrase
    }

    var body: some View {
        Form {
            titleSection
            optionSection
        }
        .animation(.easeOut, value: killphraseIsEnabled)
        .transition(.move(edge: .top))
    }

    private var titleSection: some View {
        Section {
            PlaceholderView(
                systemIcon: killphraseIsEnabled ? "bolt.badge.checkmark.fill" : "bolt",
                title: title,
                subtitle: description
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .contentTransition(.symbolEffect(.replace))
        }
    }

    private var optionSection: some View {
        Section {
            Toggle(isOn: $killphraseIsEnabled) {
                Text("Enable killphrase")
                    .font(.body)
            }

            if killphraseIsEnabled {
                FormRow(image: Image(systemName: "textformat"), color: .secondary, style: .standard) {
                    TextField("Enter killphrase...", text: $killphrase)
                        .keyboardType(.default)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .textInputAutocapitalization(.never)
                }
            }
        } footer: {
            if killphraseIsEnabled {
                Text(hiddenWithKillphraseTitle)
            }
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
