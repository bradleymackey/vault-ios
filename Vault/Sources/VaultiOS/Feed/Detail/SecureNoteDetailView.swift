import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct SecureNoteDetailView: View {
    @Bindable var viewModel: SecureNoteDetailViewModel

    @Environment(\.dismiss) var dismiss
    @State private var isError = false
    @State private var currentError: (any Error)?

    var body: some View {
        Form {
            Text(viewModel.editingModel.detail.title)
            Text(viewModel.editingModel.detail.description)
            Text(viewModel.editingModel.detail.contents)
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
