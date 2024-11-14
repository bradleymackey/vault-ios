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
        case editLock
        case editPassphrase
        case editKillphrase
        case editEncryption
        case editTags
    }

    init(
        editingExistingNote note: SecureNote,
        encryptionKey: DerivedEncryptionKey?,
        navigationPath: Binding<NavigationPath>,
        dataModel: VaultDataModel,
        storedMetadata: VaultItem.Metadata,
        editor: any SecureNoteDetailEditor,
        openInEditMode: Bool
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .editing(note: note, metadata: storedMetadata, existingKey: encryptionKey),
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
            case .editLock:
                NavigationStack {
                    VaultDetailLockEditView(
                        title: "Lock",
                        description: "Locked notes require authentication to view or edit. The title and first line of the note will be visible in the preview.",
                        lockState: $viewModel.editingModel.detail.lockState
                    )
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            case .editPassphrase:
                NavigationStack {
                    VaultDetailPassphraseEditView(
                        title: "Visibility",
                        description: "Notes that require a passphrase are hidden from the main feed. You need to search exactly for your chosen passphrase each time to view this note.",
                        hiddenWithPassphraseTitle: viewModel.strings.passphraseSubtitle,
                        viewConfig: $viewModel.editingModel.detail.viewConfig,
                        passphrase: $viewModel.editingModel.detail.searchPassphrase
                    )
                    .interactiveDismissDisabled(!viewModel.editingModel.detail.isPassphraseValid)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                            .disabled(!viewModel.editingModel.detail.isPassphraseValid)
                        }
                    }
                }
            case .editKillphrase:
                NavigationStack {
                    VaultDetailKillphraseEditView(
                        title: "Killphrase",
                        description: "A killphrase is a secret phrase that is used to immediately delete this note. In the search bar, search exactly for this text and the note will be immediately and quitely deleted. Combined with a search passphrase, you can delete an item without it being made visible.",
                        hiddenWithKillphraseTitle: viewModel.strings.killphraseSubtitle,
                        killphrase: $viewModel.editingModel.detail.killphrase
                    )
                    .interactiveDismissDisabled(!viewModel.editingModel.detail.isKillphraseValid)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                            .disabled(!viewModel.editingModel.detail.isKillphraseValid)
                        }
                    }
                }
            case .editEncryption:
                NavigationStack {
                    VaultDetailEncryptionEditView(
                        title: "Encryption",
                        description: "Add full at-rest encryption for the note. Password is required on every view."
                    )
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            case .editTags:
                NavigationStack {
                    VaultDetailTagEditView(
                        tagsThatAreSelected: viewModel.tagsThatAreSelected,
                        remainingTags: viewModel.remainingTags,
                        didAdd: { viewModel.editingModel.detail.tags.insert($0.id) },
                        didRemove: { viewModel.editingModel.detail.tags.remove($0.id) }
                    )
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
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

    // MARK: Title

    private var noteIconHeader: some View {
        Image(systemName: viewModel.editingModel.detail.lockState.isLocked ? "lock.doc.fill" : "doc.text.fill")
            .font(.title)
            .foregroundStyle(selectedColor)
    }

    private var noteIconEditingHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.editingModel.detail.lockState.isLocked ? "lock.doc.fill" : "doc.text.fill")
                .font(.largeTitle)
                .foregroundStyle(selectedColor)

            ColorPicker(selection: $selectedColor, supportsOpacity: false, label: {
                EmptyView()
            })
            .labelsHidden()
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
            noteIconEditingHeader
                .containerRelativeFrame(.horizontal)
                .padding(.vertical, 4)
                .padding(.bottom, 8)
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

            Button {
                modal = .editPassphrase
            } label: {
                FormRow(
                    image: Image(systemName: viewModel.editingModel.detail.viewConfig.systemIconName),
                    color: .accentColor,
                    style: .standard
                ) {
                    LabeledContent("Visibility", value: viewModel.editingModel.detail.viewConfig.localizedTitle)
                        .font(.body)
                }
            }

            Button {
                modal = .editKillphrase
            } label: {
                FormRow(
                    image: Image(systemName: "delete.backward"),
                    color: .accentColor,
                    style: .standard
                ) {
                    LabeledContent("Killphrase", value: viewModel.editingModel.detail.killphraseEnabledText)
                        .font(.body)
                }
            }

            Button {
                modal = .editEncryption
            } label: {
                FormRow(
                    image: Image(systemName: "lock.iphone"),
                    color: .accentColor,
                    style: .standard
                ) {
                    LabeledContent("Encryption", value: "?")
                        .font(.body)
                }
            }

            Button {
                modal = .editTags
            } label: {
                VStack {
                    FormRow(
                        image: Image(systemName: "tag"),
                        color: .accentColor,
                        style: .standard
                    ) {
                        LabeledContent(
                            "Tags",
                            value: viewModel.strings.tagCount(tags: viewModel.editingModel.detail.tags.count)
                        )
                        .font(.body)
                    }

                    if viewModel.tagsThatAreSelected.isNotEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center, spacing: 8) {
                                ForEach(viewModel.tagsThatAreSelected) { tag in
                                    TagPillView(tag: tag, isSelected: true)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .scrollClipDisabled()
                    }
                }
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
        encryptionKey: nil,
        navigationPath: .constant(.init()),
        dataModel: .init(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
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
            killphrase: "",
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
            vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        )
    )
    .environment(DeviceAuthenticationService(policy: .alwaysAllow))
}
