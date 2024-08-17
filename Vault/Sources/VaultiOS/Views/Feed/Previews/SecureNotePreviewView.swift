import SwiftUI
import VaultFeed

@MainActor
public struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel
    var behaviour: VaultItemViewBehaviour

    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: viewModel.isLocked ? "lock.doc.fill" : "doc.text.fill")
                    .font(.headline)
                    .foregroundStyle(isEditing ? .white : viewModel.color.color)
                Text(viewModel.visibleTitle)
                    .font(.headline)
            }
            .foregroundStyle(isEditing ? .white : .primary)
            .tint(.primary)
            .multilineTextAlignment(.center)
            .layoutPriority(100)

            if let description = viewModel.description, description.isNotEmpty {
                Spacer()

                Text(description)
                    .font(.callout)
                    .foregroundStyle(isEditing ? .white : .secondary)
                    .tint(.secondary)
                    .layoutPriority(99)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .padding(8)
        .shimmering(active: isEditing)
        .aspectRatio(1, contentMode: .fill)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(VaultCardModifier(context: isEditing ? .prominent : .secondary))
    }

    private var isEditing: Bool {
        switch behaviour {
        case .normal: false
        case .editingState: true
        }
    }
}

#Preview {
    SecureNotePreviewView(
        viewModel: .init(
            title: "Test title",
            description: "desc",
            color: .init(red: 0, green: 0, blue: 0),
            isLocked: true
        ),
        behaviour: .normal
    )
    .frame(width: 200, height: 200)
    .padding()
}

#Preview {
    SecureNotePreviewView(
        viewModel: .init(
            title: "Test title",
            description: "",
            color: .init(red: 0, green: 0, blue: 0),
            isLocked: false
        ),
        behaviour: .normal
    )
    .frame(width: 200, height: 200)
    .padding()
}
