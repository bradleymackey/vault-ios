import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct EncryptedItemPreviewView: View {
    var viewModel: EncryptedItemPreviewViewModel
    var behaviour: VaultItemViewBehaviour

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.subheadline.bold())
                .foregroundStyle(isEditing ? .white : viewModel.color.color)
            Text(viewModel.visibleTitle)
                .font(.subheadline.bold())

            Spacer()

            Text("Encrypted")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .foregroundStyle(isEditing ? .white : .primary)
        .tint(.primary)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .shimmering(active: isEditing)
        .aspectRatio(1, contentMode: .fill)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(
            VaultCardModifier(
                configuration: .init(style: isEditing ? .prominent : .secondary, border: viewModel.color.color),
            ),
        )
    }

    private var isEditing: Bool {
        switch behaviour {
        case .normal: false
        case .editingState: true
        }
    }
}

#Preview {
    EncryptedItemPreviewView(viewModel: .init(title: "Hello", color: .tagDefault), behaviour: .normal)
        .frame(width: 200, height: 200)
        .padding()
}
