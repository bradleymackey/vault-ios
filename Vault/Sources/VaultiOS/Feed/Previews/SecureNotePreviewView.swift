import SwiftUI
import VaultFeed

@MainActor
public struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleLabel
            if let description = viewModel.description {
                descriptionLabel(text: description)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(2)
    }

    private var titleLabel: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "doc.text.fill")
                .font(.headline)
            Text(viewModel.title)
                .font(.headline)
        }
        .padding(.vertical, 4)
        .foregroundStyle(.primary)
        .tint(.primary)
    }

    private func descriptionLabel(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .lineLimit(5)
            .foregroundStyle(.secondary)
            .tint(.secondary)
    }
}

struct SecureNotePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SecureNotePreviewView(viewModel: .init(title: "Test title", description: "desc"))
            .modifier(OTPCardViewModifier())
            .padding()
    }
}
