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
            Spacer()
        }
        .multilineTextAlignment(.leading)
        .padding(2)
        .aspectRatio(1, contentMode: .fill)
    }

    private var titleLabel: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "doc.text.fill")
            Text(viewModel.visibleTitle)
                .lineLimit(2)
        }
        .font(.callout.bold())
        .minimumScaleFactor(0.8)
        .padding(.vertical, 4)
        .foregroundStyle(.primary)
        .tint(.primary)
    }

    private func descriptionLabel(text: String) -> some View {
        Text(text)
            .font(.footnote)
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
