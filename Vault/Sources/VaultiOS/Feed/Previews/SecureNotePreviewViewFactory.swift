import Foundation
import SwiftUI
import VaultFeed

public protocol SecureNotePreviewViewFactory {
    associatedtype SecureNoteView: View
    func makeSecureNoteView(viewModel: SecureNotePreviewViewModel) -> SecureNoteView
}

public struct SecureNotePreviewViewFactoryImpl: SecureNotePreviewViewFactory {
    public init() {}
    public func makeSecureNoteView(viewModel: SecureNotePreviewViewModel) -> some View {
        SecureNotePreviewView(viewModel: viewModel)
    }
}
