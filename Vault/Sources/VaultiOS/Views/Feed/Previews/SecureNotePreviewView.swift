import SwiftUI
import VaultFeed

@MainActor
public struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel
    var behaviour: VaultItemViewBehaviour

    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.color.color)
                Text(viewModel.visibleTitle)
                    .font(.headline)
            }
            .foregroundStyle(.primary)
            .tint(.primary)
            .multilineTextAlignment(.center)
            .layoutPriority(100)

            if let description = viewModel.description, description.isNotEmpty {
                descriptionLabel(text: description)
                    .layoutPriority(99)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(2)
        .shimmering(active: isShimmering)
        .aspectRatio(1, contentMode: .fill)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var isShimmering: Bool {
        switch behaviour {
        case .normal: false
        case .editingState: true
        }
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
        SecureNotePreviewView(
            viewModel: .init(title: "Test title", description: "desc", color: .init(red: 0, green: 0, blue: 0)),
            behaviour: .normal
        )
        .frame(width: 200, height: 200)
        .modifier(OTPCardViewModifier())
        .padding()
    }
}
