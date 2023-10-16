import SwiftUI
import VaultFeed

@MainActor
public struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleLabel
            descriptionLabel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    private var titleLabel: some View {
        Text(viewModel.title)
            .font(.headline)
    }

    private var descriptionLabel: some View {
        Text(viewModel.description)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(5)
    }
}

struct SecureNotePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SecureNotePreviewView(viewModel: .init(title: "Test title", description: "desc"))
            .modifier(OTPCardViewModifier())
            .padding()
    }
}
