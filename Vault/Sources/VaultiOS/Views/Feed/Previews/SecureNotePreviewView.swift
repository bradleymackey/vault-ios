import MarkdownUI
import SwiftUI
import VaultFeed

@MainActor
struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel
    var behaviour: VaultItemViewBehaviour

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: viewModel.isLocked ? "lock.doc.fill" : "doc.text.fill")
                    .font(.headline)
                    .foregroundStyle(isEditing ? .white : viewModel.color.color)
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(isEditing ? .white : .primary)
            .tint(.primary)
            .multilineTextAlignment(.center)
            .layoutPriority(100)

            if let description {
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

    private var title: String {
        switch viewModel.textFormat {
        case .plain: viewModel.visibleTitle
        case .markdown: MarkdownContent(viewModel.visibleTitle).renderPlainText()
        }
    }

    private var description: String? {
        guard let description = viewModel.description, !description.isEmpty, !description.isBlank else { return nil }
        switch viewModel.textFormat {
        case .plain: return description
        case .markdown: return MarkdownContent(description).renderPlainText()
        }
    }
}

#Preview {
    SecureNotePreviewView(
        viewModel: .init(
            title: "## Test title",
            description: "desc",
            color: .init(red: 0, green: 0, blue: 0),
            isLocked: true,
            textFormat: .markdown
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
            isLocked: false,
            textFormat: .plain
        ),
        behaviour: .normal
    )
    .frame(width: 200, height: 200)
    .padding()
}
