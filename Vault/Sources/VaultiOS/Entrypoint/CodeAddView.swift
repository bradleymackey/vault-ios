import SwiftUI
import VaultUI

struct CodeAddView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            itemSelectionSection
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
        }
        .foregroundStyle(.primary)
    }
}
