import FoundationExtensions
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
            noteDetailSection
            if viewModel.isInEditMode {
                noteDetailEditingSection
            }
            noteContentsSection
            if !viewModel.isInEditMode {
                metadataSection
            }
        }
    }

    private var noteDetailSection: some View {
        Section {
            if viewModel.isInEditMode {
                noteDetailContentEditing
            } else {
                noteDetailContent
            }
        }
        .keyboardType(.default)
        .textInputAutocapitalization(.sentences)
        .submitLabel(.done)
    }

    @ViewBuilder
    private var noteDetailContent: some View {
        VStack(alignment: .center, spacing: 4) {
            if viewModel.editingModel.detail.title.isNotEmpty {
                Text(viewModel.editingModel.detail.title)
                    .font(.title.bold())
            }
        }
        .lineLimit(5)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .noListBackground()

        if viewModel.editingModel.detail.description.isNotEmpty {
            VStack(alignment: .center) {
                Text(viewModel.editingModel.detail.description)
            }
            .frame(maxWidth: .infinity)
            .noListBackground()
            .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var noteDetailContentEditing: some View {
        TextField(
            viewModel.strings.noteTitle,
            text: $viewModel.editingModel.detail.title
        )
    }

    private var noteDetailEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .frame(minHeight: 100)
        } header: {
            Text(viewModel.strings.noteDescription)
        }
    }

    private var noteContentsSection: some View {
        Section {
            if viewModel.isInEditMode {
                TextEditor(text: $viewModel.editingModel.detail.contents)
                    .frame(minHeight: 200)
                    .font(.callout)
                    .fontDesign(.monospaced)
            } else {
                Text(viewModel.editingModel.detail.contents)
                    .textSelection(.enabled)
                    .font(.callout)
                    .fontDesign(.monospaced)
                    .noListBackground()
            }
        } header: {
            if viewModel.isInEditMode {
                Text(viewModel.strings.noteContentsTitle)
            }
        } footer: {
            if viewModel.isInEditMode {
                deleteButton
                    .modifier(HorizontallyCenter())
                    .padding()
                    .padding(.vertical, 16)
            }
        }
    }

    private var metadataSection: some View {
        Section {
            Label {
                LabeledContent(viewModel.strings.createdDateTitle, value: viewModel.createdDateValue)
            } icon: {
                RowIcon(icon: Image(systemName: "clock.fill"), color: .blue)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 2)

            if viewModel.updatedDateValue != viewModel.createdDateValue {
                Label {
                    LabeledContent(viewModel.strings.updatedDateTitle, value: viewModel.updatedDateValue)
                } icon: {
                    RowIcon(icon: Image(systemName: "clock.arrow.2.circlepath"), color: .green)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 2)
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
