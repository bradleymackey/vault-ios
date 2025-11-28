import Foundation
import SwiftUI
import VaultFeed

/// @mockable(typealias: SecureNoteView = AnyView)
@MainActor
public protocol SecureNotePreviewViewFactory {
    associatedtype SecureNoteView: View
    func makeSecureNoteView(viewModel: SecureNotePreviewViewModel, behaviour: VaultItemViewBehaviour) -> SecureNoteView
}

public struct SecureNotePreviewViewFactoryImpl: SecureNotePreviewViewFactory {
    public func makeSecureNoteView(
        viewModel: SecureNotePreviewViewModel,
        behaviour: VaultItemViewBehaviour,
    ) -> some View {
        SecureNotePreviewView(viewModel: viewModel, behaviour: behaviour)
    }
}
