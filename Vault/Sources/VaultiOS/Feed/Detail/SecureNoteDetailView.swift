import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
struct SecureNoteDetailView: View {
    @State private var viewModel: SecureNoteDetailViewModel
    @Binding private var navigationPath: NavigationPath
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedColor: Color

    init(
        editingExistingNote note: SecureNote,
        navigationPath: Binding<NavigationPath>,
        storedMetadata: VaultItem.Metadata,
        editor: any SecureNoteDetailEditor,
        openInEditMode: Bool
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(mode: .editing(note: note, metadata: storedMetadata), editor: editor))
        _selectedColor = State(initialValue: storedMetadata.color?.color ?? VaultItemColor.default.color)

        if openInEditMode {
            viewModel.startEditing()
        }
    }

    init(newNoteWithEditor editor: any SecureNoteDetailEditor, navigationPath: Binding<NavigationPath>) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(mode: .creating, editor: editor))
        _selectedColor = .init(initialValue: VaultItemColor.default.color)

        viewModel.startEditing()
    }

    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        VaultItemDetailView(
            viewModel: viewModel,
            currentError: $currentError,
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation,
            navigationPath: $navigationPath,
            presentationMode: presentationMode
        ) {
            if viewModel.isInEditMode {
                noteTitleEditingSection
                noteDescriptionEditingSection
                noteContentsEditingSection
                viewConfigEditingSection
                if viewModel.editingModel.detail.viewConfig.needsPassphrase {
                    passphraseEntrySection
                }
                if viewModel.shouldShowDeleteButton {
                    deleteSection
                }
            } else {
                noteMetadataContentSection
                noteContentsSection
            }
        }
        .animation(.easeOut, value: viewModel.editingModel.detail.viewConfig)
        .onChange(of: selectedColor.hashValue) { _, _ in
            viewModel.editingModel.detail.color = VaultItemColor(color: selectedColor)
        }
    }

    // MARK: Title & Description

    private var noteMetadataContentSection: some View {
        Section {
            noteIconHeader
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)

            Text(viewModel.visibleTitle)
                .foregroundStyle(.primary)
                .font(.title.bold())
                .lineLimit(5)
                .frame(maxWidth: .infinity)

            if viewModel.editingModel.detail.description.isNotEmpty {
                Text(viewModel.editingModel.detail.description)
                    .foregroundStyle(.secondary)
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
                Text(viewModel.strings.noteTitle)
            }
        } header: {
            noteIconPickerHeader
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

    private var noteIconHeader: some View {
        Image(systemName: "doc.text.fill")
            .font(.largeTitle)
            .foregroundStyle(selectedColor)
    }

    private var noteIconPickerHeader: some View {
        VStack(spacing: 8) {
            noteIconHeader

            ColorPicker(selection: $selectedColor, supportsOpacity: false, label: {
                EmptyView()
            })
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.detailEntries) { item in
                    FooterInfoLabel(title: item.title, detail: item.detail, systemImageName: item.systemIconName)
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
        }
    }

    private var viewConfigEditingSection: some View {
        Section {
            Picker(selection: $viewModel.editingModel.detail.viewConfig) {
                ForEach(VaultItemViewConfiguration.allCases) { visibility in
                    DetailSubtitleView(
                        systemIcon: visibility.systemIconName,
                        title: visibility.localizedTitle,
                        subtitle: visibility.localizedSubtitle
                    )
                    .tag(visibility)
                }
            } label: {
                Text(viewModel.strings.visibilityTitle)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text(viewModel.strings.noteVisibilityTitle)
        }
    }

    private var passphraseEntrySection: some View {
        Section {
            TextField(viewModel.strings.passphrasePrompt, text: $viewModel.editingModel.detail.searchPassphrase)
        } header: {
            Text(viewModel.strings.passphraseTitle)
        } footer: {
            Text(viewModel.strings.passphraseSubtitle)
        }
    }

    private var deleteSection: some View {
        Section {
            Button {
                isShowingDeleteConfirmation = true
            } label: {
                FormRow(image: .init(systemName: "trash.fill"), color: .red, style: .standard) {
                    Text(localized(key: "action.delete.title"))
                        .fontWeight(.medium)
                }
            }
            .foregroundStyle(.red)
        }
    }
}
