import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct SecureNoteDetailView: View {
    @Bindable var viewModel: SecureNoteDetailViewModel

    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        VaultItemDetailView(
            viewModel: viewModel,
            currentError: $currentError,
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation
        ) {
            Text(viewModel.editingModel.detail.title)
            Text(viewModel.editingModel.detail.description)
            Text(viewModel.editingModel.detail.contents)
        }
    }
}
