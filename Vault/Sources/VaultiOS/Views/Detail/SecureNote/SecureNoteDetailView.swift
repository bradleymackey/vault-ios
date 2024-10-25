import MarkdownUI
import SwiftUI
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
        case editLock
    }

    init(
        editingExistingNote note: SecureNote,
        navigationPath: Binding<NavigationPath>,
        dataModel: VaultDataModel,
        storedMetadata: VaultItem.Metadata,
        editor: any SecureNoteDetailEditor,
        openInEditMode: Bool
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .editing(note: note, metadata: storedMetadata),
            dataModel: dataModel,
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
        dataModel: VaultDataModel
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .creating,
            dataModel: dataModel,
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
                noteContentsEditingSection
                if viewModel.allTags.isNotEmpty {
                    tagSelectionSection
                }
                passphraseEditingSection
                if viewModel.shouldShowDeleteButton {
                    deleteSection
                }
            } else {
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
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            case .editLock:
                NavigationStack {
                    VaultDetailLockItemView(
                        title: "Lock",
                        description: "Locked notes require authentication to view or edit. The title and first line of the note will be visible in the preview.",
                        lockState: $viewModel.editingModel.detail.lockState
                    )
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
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
                .containerRelativeFrame(.horizontal)
                .padding()
                .foregroundStyle(.secondary)
            }

            ForEach(viewModel.tagsThatAreSelected) { tag in
                FormRow(
                    image: Image(systemName: tag.iconName),
                    color: tag.color.color,
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
                        image: Image(systemName: tag.iconName),
                        color: tag.color.color,
                        style: .standard
                    ) {
                        Text(tag.name)
                    }
                }
            }
        }
    }

    // MARK: Title

    private var noteIconHeader: some View {
        Image(systemName: viewModel.editingModel.detail.isLocked ? "lock.doc.fill" : "doc.text.fill")
            .font(.title)
            .foregroundStyle(selectedColor)
    }

    private var noteIconPickerHeader: some View {
        HStack(spacing: 8) {
            noteIconHeader
                .padding(8)
                .background(Circle().fill(Color(UIColor.secondarySystemBackground)))
                .padding(8)
                .background(Circle().fill(AngularGradient(
                    gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .pink]),
                    center: .center
                ).opacity(0.8)))
                .overlay(ColorPicker("", selection: $selectedColor).labelsHidden().opacity(0.015))
        }
    }

    // MARK: Contents

    private var noteContentsSection: some View {
        Section {
            switch viewModel.editingModel.detail.textFormat {
            case .plain:
                SelectableText(
                    viewModel.editingModel.detail.contents,
                    fontStyle: .monospace,
                    textStyle: .callout
                )
                .frame(minHeight: 450, alignment: .top)
            case .markdown:
                Markdown(.init(viewModel.editingModel.detail.contents))
                    .textSelection(.enabled)
                    .frame(minHeight: 450, alignment: .top)
            }
        } header: {
            noteIconHeader
                .containerRelativeFrame(.horizontal)
                .padding(.vertical, 4)
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
            noteIconPickerHeader
                .containerRelativeFrame(.horizontal)
                .padding(.vertical, 4)
        }
    }

    private var passphraseEditingSection: some View {
        Section {
            Picker(selection: $viewModel.editingModel.detail.textFormat) {
                ForEach(TextFormat.allCases, id: \.self) { format in
                    Text(format.localizedString)
                        .tag(format)
                }
            } label: {
                FormRow(image: Image(systemName: "text.justify.left"), color: .accentColor, style: .standard) {
                    Text("Text Format")
                }
            }

            Button {
                modal = .editLock
            } label: {
                FormRow(
                    image: Image(systemName: viewModel.editingModel.detail.lockState.systemIconName),
                    color: .accentColor,
                    style: .standard
                ) {
                    LabeledContent("Lock", value: viewModel.editingModel.detail.lockState.localizedTitle)
                        .font(.body)
                }
            }

            Toggle(isOn: $viewModel.editingModel.detail.isHiddenWithPassphrase) {
                FormRow(
                    image: Image(systemName: viewModel.editingModel.detail.viewConfig.systemIconName),
                    color: viewModel.editingModel.detail.isHiddenWithPassphrase ? .red : .green,
                    style: .prominent
                ) {
                    VStack(alignment: .leading) {
                        Text("Hide with passphrase")
                            .font(.body)
                        Text("Hide this note from being visible in the feed")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if viewModel.editingModel.detail.isHiddenWithPassphrase {
                FormRow(image: Image(systemName: "entry.lever.keypad.fill"), color: .blue, style: .standard) {
                    TextField(viewModel.strings.passphrasePrompt, text: $viewModel.editingModel.detail.searchPassphrase)
                        .keyboardType(.default)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .textInputAutocapitalization(.never)
                }
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

#Preview("Viewing") {
    SecureNoteDetailView(
        editingExistingNote: .init(
            title: "Hello",
            contents: "This is the contents, it is long \n\n## Nice title",
            format: .markdown
        ),
        navigationPath: .constant(.init()),
        dataModel: .init(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        storedMetadata: .init(
            id: .init(),
            created: .init(),
            updated: .init(),
            relativeOrder: 0,
            userDescription: "testing",
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "",
            lockState: .notLocked,
            color: nil
        ),
        editor: SecureNoteDetailEditorMock(),
        openInEditMode: false
    )
    .environment(DeviceAuthenticationService(policy: .alwaysAllow))
}

#Preview("Editing") {
    SecureNoteDetailView(
        newNoteWithEditor: SecureNoteDetailEditorMock(),
        navigationPath: .init(projectedValue: .constant(.init())),
        dataModel: .init(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        )
    )
    .environment(DeviceAuthenticationService(policy: .alwaysAllow))
}
