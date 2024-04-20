import Foundation
import SwiftUI
import VaultFeed

/// The basis of a detail view with some of the editing state already bound to buttons etc.
@MainActor
struct VaultItemDetailView<ChildViewModel: DetailViewModel, ContentsView: View>: View {
    @Bindable var viewModel: ChildViewModel
    @Binding var currentError: (any Error)?
    @Binding var isShowingDeleteConfirmation: Bool
    @ViewBuilder var contents: () -> ContentsView

    @Environment(\.dismiss) private var dismiss
    @State private var isError = false

    var body: some View {
        Form {
            contents()
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.editingModel.isDirty)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeOut, value: viewModel.isInEditMode)
        .onReceive(viewModel.isFinishedPublisher()) {
            dismiss()
        }
        .onReceive(viewModel.didEncounterErrorPublisher()) { error in
            currentError = error
            isError = true
        }
        .confirmationDialog(
            viewModel.strings.deleteConfirmTitle,
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(viewModel.strings.deleteItemTitle, role: .destructive) {
                Task { await viewModel.delete() }
            }
        } message: {
            Text(viewModel.strings.deleteConfirmSubtitle)
        }
        .alert(localized(key: "action.error.title"), isPresented: $isError, presenting: currentError) { _ in
            Button(localized(key: "action.error.confirm.title"), role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .toolbar {
            if viewModel.editingModel.isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.done()
                    } label: {
                        Text(viewModel.strings.cancelEditsTitle)
                            .tint(.red)
                    }
                }
            } else if !viewModel.isInEditMode {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.startEditing()
                    } label: {
                        Text(viewModel.strings.startEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }

            if viewModel.editingModel.isDirty {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.saveChanges() }
                    } label: {
                        Text(viewModel.strings.saveEditsTitle)
                            .tint(.accentColor)
                    }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.done()
                    } label: {
                        Text(viewModel.strings.doneEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }
        }
    }
}
