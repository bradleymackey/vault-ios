import SwiftUI
import VaultUI

struct CodeAddView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            itemSelectionSection
        }
        .navigationTitle(Text("Add Item"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var itemSelectionSection: some View {
        Section {
            NavigationLink(destination: Text("Coming Soon")) {
                FormRow(image: Image(systemName: "qrcode"), color: .blue) {
                    Text("2FA Code")
                }
            }

            NavigationLink(destination: Text("Coming Soon")) {
                FormRow(image: Image(systemName: "text.alignleft"), color: .blue) {
                    Text("Private Note")
                }
            }

            NavigationLink(destination: Text("Coming Soon")) {
                FormRow(image: Image(systemName: "bitcoinsign"), color: .blue) {
                    Text("Cryptocurrency Seed Phrase")
                }
            }
        } footer: {
            Text("Store a new item securely on your device.")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }
}
