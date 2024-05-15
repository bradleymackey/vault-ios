import Foundation
import SwiftUI
import VaultFeed

/// The basis of a detail view with some of the editing state already bound to buttons etc.
@MainActor
struct VaultItemDetailView<ChildViewModel: DetailViewModel, ContentsView: View>: View {
    @Bindable var viewModel: ChildViewModel
    @Binding var currentError: (any Error)?
    @Binding var isShowingDeleteConfirmation: Bool
    @Binding var navigationPath: NavigationPath
    var presentationMode: Binding<PresentationMode>?
    @ViewBuilder var contents: () -> ContentsView

    @State private var isError = false

    private func dismiss() {
        presentationMode?.wrappedValue.dismiss()
    }

    var body: some View {
        Form {
            contents()
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.editingModel.isDirty)
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
            // Only if this view is the root of the navigation stack should we show these actions.
            // If it isn't, it implies going back to the original context is more likely the correct
            // action to take.
            if navigationPath.isEmpty {
                if viewModel.isInitialCreation {
                    cancelCreationItem
                } else {
                    if viewModel.editingModel.isDirty {
                        cancelEditsItem
                    } else if !viewModel.isInEditMode {
                        startEditingItem
                    }
                }
            }

            if viewModel.editingModel.isDirty {
                saveDirtyChangesItem
            } else {
                // Don't show the "done" item during initial creation if not dirty
                // The only option should be to cancel.
                if !viewModel.isInitialCreation {
                    doneItem
                }
            }
        }
    }

    private var cancelCreationItem: some ToolbarContent {
        // This button always dismisses immediately (without saving) if it's the initial creation.
        // (Dirty or not!)
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Text(viewModel.strings.cancelEditsTitle)
                    .tint(.red)
            }
        }
    }

    private var cancelEditsItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                viewModel.done()
            } label: {
                Text(viewModel.strings.cancelEditsTitle)
                    .tint(.red)
            }
        }
    }

    private var startEditingItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                viewModel.startEditing()
            } label: {
                Text(viewModel.strings.startEditingTitle)
                    .tint(.accentColor)
            }
        }
    }

    private var saveDirtyChangesItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                Task { await viewModel.saveChanges() }
            } label: {
                Text(viewModel.strings.saveEditsTitle)
                    .tint(.accentColor)
            }
            .disabled(!viewModel.editingModel.isValid)
        }
    }

    private var doneItem: some ToolbarContent {
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
