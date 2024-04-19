import SwiftUI
import VaultFeed

@MainActor
public struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel

    public var body: some View {
        VStack(alignment: .leading) {
            titleLabel
            if let description = viewModel.description {
                Divider()
                    .padding(.bottom, 2)
                descriptionLabel(text: description)
            }
            Spacer()
        }
        .multilineTextAlignment(.leading)
        .padding(2)
        .aspectRatio(1, contentMode: .fill)
    }

    private var titleLabel: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "doc.text.fill")
                .font(.body)
            Text(viewModel.title)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .foregroundStyle(.primary)
        .tint(.primary)
    }

    private func descriptionLabel(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .tint(.secondary)
    }
}

struct SecureNotePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SecureNotePreviewView(viewModel: .init(title: "Test title", description: "desc"))
            .frame(width: 200, height: 200)
            .modifier(OTPCardViewModifier())
            .padding()
    }
}
