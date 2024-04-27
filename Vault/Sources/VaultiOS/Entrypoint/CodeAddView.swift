import SwiftUI
import VaultUI

struct CodeAddView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            gridOfItems
                .padding()
        }
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

    private var gridOfItems: some View {
        LazyVGrid(columns: columns) {
            NavigationLink(destination: Text("Coming Soon")) {
                row(icon: "qrcode", title: "2FA Code")
            }

            NavigationLink(destination: Text("Coming Soon")) {
                row(icon: "text.alignleft", title: "Note")
            }

            NavigationLink(destination: Text("Coming Soon")) {
                row(icon: "bitcoinsign", title: "Seed Phrase")
            }
        }
    }

    private var columns: [GridItem] {
        [
            .init(.adaptive(minimum: 100, maximum: 150), spacing: 16),
        ]
    }

    private func row(icon: String, title: String) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .modifier(OTPCardViewModifier())
            Text(title)
                .font(.callout)
                .foregroundStyle(.foreground)
        }
    }
}
