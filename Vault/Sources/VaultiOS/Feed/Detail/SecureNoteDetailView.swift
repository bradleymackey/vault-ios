import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct SecureNoteDetailView: View {
    @State private var viewModel: SecureNoteDetailViewModel

    init(
        editingExistingNote note: SecureNote,
        storedMetadata: StoredVaultItem.Metadata,
        editor: any SecureNoteDetailEditor,
        openInEditMode: Bool
    ) {
        _viewModel = .init(initialValue: .init(mode: .editing(note: note, metadata: storedMetadata), editor: editor))

        if openInEditMode {
            viewModel.startEditing()
        }
    }

    init(newNoteWithEditor editor: any SecureNoteDetailEditor) {
        _viewModel = .init(initialValue: .init(mode: .creating, editor: editor))

        viewModel.startEditing()
    }

    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        VaultItemDetailView(
            viewModel: viewModel,
            currentError: $currentError,
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation
        ) {
            if viewModel.isInEditMode {
                noteTitleEditingSection
                noteDescriptionEditingSection
                noteContentsEditingSection
            } else {
                noteMetadataContentSection
                noteContentsSection
            }
        }
    }

    // MARK: Title & Description

    private var noteMetadataContentSection: some View {
        Section {
            Text(viewModel.visibleTitle)
                .font(.title.bold())
                .lineLimit(5)
                .frame(maxWidth: .infinity)

            if viewModel.editingModel.detail.description.isNotEmpty {
                Text(viewModel.editingModel.detail.description)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
            }
        }
        .multilineTextAlignment(.center)
        .textSelection(.enabled)
        .noListBackground()
    }

    private var noteTitleEditingSection: some View {
        Section {
            TextField(text: $viewModel.editingModel.detail.title) {
                Text(viewModel.strings.noteTitleExample)
            }
        } header: {
            Text(viewModel.strings.noteTitle)
        } footer: {
            switch viewModel.editingModel.detail.$title {
            case let .error(.some(message)):
                Text(message)
                    .foregroundStyle(Color.red)
            case _:
                EmptyView()
            }
        }
    }

    private var noteDescriptionEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .font(.callout)
                .frame(minHeight: 60)
        } header: {
            Text(viewModel.strings.noteDescription)
        }
    }

    // MARK: Contents

    private var noteContentsSection: some View {
        Section {
            SelectableText(
                viewModel.editingModel.detail.contents,
                fontStyle: .monospace,
                textStyle: .body
            )
            .frame(minHeight: 250, alignment: .top)
        } footer: {
            VStack(alignment: .leading, spacing: 2) {
                if let createdDate = viewModel.createdDateValue {
                    FooterInfoLabel(
                        title: viewModel.strings.createdDateTitle,
                        detail: createdDate,
                        systemImageName: "clock.fill"
                    )

                    if let updatedDate = viewModel.updatedDateValue {
                        FooterInfoLabel(
                            title: viewModel.strings.updatedDateTitle,
                            detail: updatedDate,
                            systemImageName: "clock.arrow.2.circlepath"
                        )
                    }
                }
            }
            .font(.footnote)
            .padding(.top, 8)
            .transition(.opacity)
        }
    }

    private var noteContentsEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.contents)
                .font(.callout)
                .fontDesign(.monospaced)
                .frame(minHeight: 250)
        } header: {
            Text(viewModel.strings.noteContentsTitle)
        } footer: {
            if viewModel.shouldShowDeleteButton {
                deleteButton
                    .modifier(HorizontallyCenter())
                    .padding()
                    .padding(.vertical, 16)
                    .transition(.opacity)
            }
        }
    }

    private var deleteButton: some View {
        Button {
            isShowingDeleteConfirmation = true
        } label: {
            ItemDeleteLabel()
        }
    }
}
