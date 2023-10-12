import SwiftUI
import VaultUI

struct CodeAddView: View {
    var body: some View {
        Form {
            itemSelectionSection
        }
        .foregroundStyle(.primary)
    }

    private var itemSelectionSection: some View {
        Section {
            Button {
                print("add 2FA code flow")
            } label: {
                FormRow(image: Image(systemName: "qrcode"), color: .blue) {
                    Text("2FA Code")
                }
            }

            Button {
                print("add note flow")
            } label: {
                FormRow(image: Image(systemName: "text.alignleft"), color: .blue) {
                    Text("Private Note")
                }
            }

            Button {
                print("add crypto seed word flow")
            } label: {
                FormRow(image: Image(systemName: "bitcoinsign"), color: .blue) {
                    Text("Cryptocurrency Seed Phrase")
                }
            }
        } footer: {
            Text("Store a new item securely on your device.")
                .foregroundStyle(.secondary)
        }
    }
}
