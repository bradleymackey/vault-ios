import MarkdownUI
import SwiftUI
import VaultFeed

@MainActor
struct SecureNotePreviewView: View {
    var viewModel: SecureNotePreviewViewModel
    var behaviour: VaultItemViewBehaviour

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: viewModel.isLocked ? "lock.doc.fill" : "doc.text.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isEditing ? .white.opacity(0.8) : viewModel.color.color.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            Text(title)
                .font(titleFont)
                .foregroundStyle(isEditing ? .white : .primary)
                .lineLimit(description != nil ? 3 : nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let description {
                ZStack(alignment: .topLeading) {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(isEditing ? .white.opacity(0.85) : .secondary)
                        .lineSpacing(3)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .mask {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(.white)
                                LinearGradient(
                                    colors: [.white, .white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom,
                                )
                                .frame(height: 40)
                            }
                        }
                }
                .padding(.top, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .shimmering(active: isEditing)
        .modifier(
            VaultCardModifier(
                configuration: .init(
                    style: isEditing ? .prominent : .secondary,
                    border: viewModel.color.color,
                    padding: .init(),
                ),
            ),
        )
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
        guard let description = viewModel.description, description.isNotBlank else { return nil }
        switch viewModel.textFormat {
        case .plain: return description
        case .markdown: return MarkdownContent(description).renderPlainText()
        }
    }

    private var titleFont: Font {
        let length = title.count
        let hasDescription = description != nil

        // Base font size depends on whether there's a description
        let baseFonts: (Font, Font, Font, Font) = hasDescription
            ? (
                .title3.weight(.bold),
                .system(size: 18, weight: .bold),
                .system(size: 16, weight: .bold),
                .system(size: 14, weight: .bold),
            )
            : (.title.weight(.heavy), .title2.weight(.heavy), .title3.weight(.heavy), .system(size: 20, weight: .heavy))

        switch length {
        case 0 ... 25:
            return baseFonts.0
        case 26 ... 40:
            return baseFonts.1
        case 41 ... 55:
            return baseFonts.2
        default:
            return baseFonts.3
        }
    }
}

#Preview {
    SecureNotePreviewView(
        viewModel: .init(
            title: "## Test title",
            description: "This is a test description. It's a little long, but that's OK. This is a test description. It's a little long, but that's OK. This is a test description. It's a little long, but that's OK.",
            color: .init(red: 0, green: 0, blue: 0),
            isLocked: true,
            textFormat: .markdown,
        ),
        behaviour: .normal,
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
            textFormat: .plain,
        ),
        behaviour: .normal,
    )
    .frame(width: 200, height: 200)
    .padding()
}

#Preview {
    SecureNotePreviewView(
        viewModel: .init(
            title: "This is a somewhat longer title with more detail",
            description: "",
            color: .init(red: 0, green: 0, blue: 0),
            isLocked: false,
            textFormat: .plain,
        ),
        behaviour: .normal,
    )
    .frame(width: 200, height: 200)
    .padding()
}
