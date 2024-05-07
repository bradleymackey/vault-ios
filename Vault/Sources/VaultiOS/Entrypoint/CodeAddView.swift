import SwiftUI
import VaultUI

struct CodeAddView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var creatingItem: CreatingItem?

    var body: some View {
        ScrollView {
            gridOfItems
                .padding()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    creatingItem = nil
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
            Button {
                creatingItem = .otpCode
                dismiss()
            } label: {
                row(icon: "qrcode", title: "2FA Code")
            }

            Button {
                creatingItem = .secureNote
                dismiss()
            } label: {
                row(icon: "text.alignleft", title: "Note")
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
