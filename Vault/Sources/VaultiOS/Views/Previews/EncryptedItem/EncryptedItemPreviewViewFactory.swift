import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: ItemView = AnyView)
@MainActor
protocol EncryptedItemPreviewViewFactory {
    associatedtype ItemView: View
    func makeEncryptedItemView(viewModel: EncryptedItemPreviewViewModel, behaviour: VaultItemViewBehaviour) -> ItemView
}

struct EncryptedItemPreviewViewFactoryImpl: EncryptedItemPreviewViewFactory {
    func makeEncryptedItemView(
        viewModel: EncryptedItemPreviewViewModel,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        EncryptedItemPreviewView(viewModel: viewModel, behaviour: behaviour)
    }
}
