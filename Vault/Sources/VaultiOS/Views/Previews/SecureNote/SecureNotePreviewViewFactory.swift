import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: SecureNoteView = AnyView)
@MainActor
protocol SecureNotePreviewViewFactory {
    associatedtype SecureNoteView: View
    func makeSecureNoteView(viewModel: SecureNotePreviewViewModel, behaviour: VaultItemViewBehaviour) -> SecureNoteView
}

struct SecureNotePreviewViewFactoryImpl: SecureNotePreviewViewFactory {
    func makeSecureNoteView(
        viewModel: SecureNotePreviewViewModel,
        behaviour: VaultItemViewBehaviour
    ) -> some View {
        SecureNotePreviewView(viewModel: viewModel, behaviour: behaviour)
    }
}
