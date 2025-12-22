import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct EncryptedItemPreviewView: View {
    var viewModel: EncryptedItemPreviewViewModel
    var behaviour: VaultItemViewBehaviour

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon - small and subtle at top
            Image(systemName: "lock.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isEditing ? .white.opacity(0.8) : viewModel.color.color.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            // Title - emphasized and large
            Text(viewModel.visibleTitle)
                .font(titleFont)
                .foregroundStyle(isEditing ? .white : .primary)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Encrypted label at bottom
            Text("Encrypted")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isEditing ? .white.opacity(0.6) : .secondary.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var titleFont: Font {
        let length = viewModel.visibleTitle.count
        switch length {
        case 0 ... 25:
            return .title.weight(.heavy)
        case 26 ... 40:
            return .title2.weight(.heavy)
        case 41 ... 55:
            return .title3.weight(.heavy)
        default:
            return .system(size: 20, weight: .heavy)
        }
    }
}

#Preview {
    EncryptedItemPreviewView(viewModel: .init(title: "Hello", color: .tagDefault), behaviour: .normal)
        .frame(width: 200, height: 200)
        .padding()
}

#Preview {
    EncryptedItemPreviewView(
        viewModel: .init(title: "Hello Hello Hello Hello Hello Hello Hello", color: .tagDefault),
        behaviour: .normal,
    )
    .frame(width: 200, height: 200)
    .padding()
}
