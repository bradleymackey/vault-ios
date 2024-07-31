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
    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case tagSelector
    }

    init(
        editingExistingNote note: SecureNote,
        navigationPath: Binding<NavigationPath>,
        allTags: [VaultItemTag],
        storedMetadata: VaultItem.Metadata,
        editor: any SecureNoteDetailEditor,
        openInEditMode: Bool
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .editing(note: note, metadata: storedMetadata),
            allTags: allTags,
            editor: editor
        ))
        _selectedColor = State(initialValue: storedMetadata.color?.color ?? VaultItemColor.default.color)

        if openInEditMode {
            viewModel.startEditing()
        }
    }

    init(
        newNoteWithEditor editor: any SecureNoteDetailEditor,
        navigationPath: Binding<NavigationPath>,
        allTags: [VaultItemTag]
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .creating,
            allTags: allTags,
            editor: editor
        ))
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
                if viewModel.allTags.isNotEmpty {
                    tagSelectionSection
                }
                passphraseEditingSection
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
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
            case .tagSelector:
                NavigationStack {
                    VaultTagSelectorView(currentTags: viewModel.remainingTags) { selectedTag in
                        viewModel.editingModel.detail.tags.insert(selectedTag.id)
                    }
                    .navigationTitle(Text("Add Tag"))
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Tags

    private var tagSelectionSection: some View {
        Section {
            if viewModel.tagsThatAreSelected.isEmpty {
                PlaceholderView(
                    systemIcon: "tag.fill",
                    title: "None",
                    subtitle: "Add a tag to categorize this item"
                )
                .modifier(HorizontallyCenter())
                .padding()
            }

            ForEach(viewModel.tagsThatAreSelected) { tag in
                FormRow(
                    image: Image(systemName: tag.iconName ?? VaultItemTag.defaultIconName),
                    color: tag.color?.color ?? .primary,
                    style: .standard
                ) {
                    Text(tag.name)
                }
            }
            .onDelete { indexes in
                let tagIds = viewModel.tagsThatAreSelected.map(\.id)
                let tagsToRemove = indexes.map { tagIds[$0] }
                for tag in tagsToRemove {
                    viewModel.editingModel.detail.tags.remove(tag)
                }
            }
        } header: {
            HStack(alignment: .center) {
                Text("Tags")
                Spacer()
                if viewModel.remainingTags.isNotEmpty {
                    Button {
                        modal = .tagSelector
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .listRowSeparator(viewModel.tagsThatAreSelected.isEmpty ? .hidden : .automatic)
    }

    private var tagSelectorList: some View {
        List {
            ForEach(viewModel.remainingTags) { tag in
                Button {
                    viewModel.editingModel.detail.tags.insert(tag.id)
                } label: {
                    FormRow(
                        image: Image(systemName: tag.iconName ?? VaultItemTag.defaultIconName),
                        color: tag.color?.color ?? .primary,
                        style: .standard
                    ) {
                        Text(tag.name)
                    }
                }
            }
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
                .listRowInsets(EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16))
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
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.tagsThatAreSelected.isNotEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.tagsThatAreSelected) { tag in
                                TagPillView(tag: tag, isSelected: true)
                                    .id(tag)
                            }
                        }
                        .font(.callout)
                    }
                    .scrollClipDisabled()
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.detailEntries) { item in
                        FooterInfoLabel(title: item.title, detail: item.detail, systemImageName: item.systemIconName)
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
                .frame(minHeight: 350)
                .keyboardType(.default)
                .listRowInsets(EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16))
        } header: {
            Text(viewModel.strings.noteContentsTitle)
        }
    }

    private var passphraseEditingSection: some View {
        Section {
            Toggle(isOn: $viewModel.editingModel.detail.isHiddenWithPassphrase) {
                FormRow(
                    image: Image(systemName: viewModel.editingModel.detail.viewConfig.systemIconName),
                    color: .primary,
                    style: .standard
                ) {
                    Text("Hide with passphrase")
                        .font(.body)
                }
            }
            if viewModel.editingModel.detail.isHiddenWithPassphrase {
                TextField(viewModel.strings.passphrasePrompt, text: $viewModel.editingModel.detail.searchPassphrase)
            }
        } header: {
            Text(viewModel.strings.noteVisibilityTitle)
        } footer: {
            if viewModel.editingModel.detail.isHiddenWithPassphrase {
                Text(viewModel.strings.passphraseSubtitle)
            }
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
