import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: ItemView = AnyView)
@MainActor
public protocol EncryptedItemPreviewViewFactory {
    associatedtype ItemView: View
    func makeEncryptedItemView(viewModel: EncryptedItemPreviewViewModel, behaviour: VaultItemViewBehaviour) -> ItemView
}

public struct EncryptedItemPreviewViewFactoryImpl: EncryptedItemPreviewViewFactory {
    public func makeEncryptedItemView(
        viewModel: EncryptedItemPreviewViewModel,
        behaviour: VaultItemViewBehaviour,
    ) -> some View {
        EncryptedItemPreviewView(viewModel: viewModel, behaviour: behaviour)
    }
}
