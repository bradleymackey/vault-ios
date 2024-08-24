import SimpleToast
import SwiftUI
import VaultFeed

@MainActor
struct OTPCodeDetailView<PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler>: View
    where PreviewGenerator.PreviewItem == VaultItem.Payload
{
    @State private var viewModel: OTPCodeDetailViewModel
    private var previewGenerator: PreviewGenerator
    @Binding var navigationPath: NavigationPath
    private var presentationMode: Binding<PresentationMode>?

    @Environment(Pasteboard.self) private var pasteboard: Pasteboard
    @State private var selectedColor: Color
    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingCopyPaste = false
    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case tagSelector
    }

    init(
        editingExistingCode code: OTPAuthCode,
        navigationPath: Binding<NavigationPath>,
        dataModel: VaultDataModel,
        storedMetadata: VaultItem.Metadata,
        editor: any OTPCodeDetailEditor,
        previewGenerator: PreviewGenerator,
        openInEditMode: Bool,
        presentationMode: Binding<PresentationMode>?
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .editing(code: code, metadata: storedMetadata),
            dataModel: dataModel,
            editor: editor
        ))
        self.previewGenerator = previewGenerator
        self.presentationMode = presentationMode
        _selectedColor = State(initialValue: storedMetadata.color?.color ?? VaultItemColor.default.color)

        if openInEditMode {
            viewModel.startEditing()
        }
    }

    init(
        newCodeWithContext initialCode: OTPAuthCode?,
        navigationPath: Binding<NavigationPath>,
        dataModel: VaultDataModel,
        editor: any OTPCodeDetailEditor,
        previewGenerator: PreviewGenerator,
        presentationMode: Binding<PresentationMode>?
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(
            mode: .creating(initialCode: initialCode),
            dataModel: dataModel,
            editor: editor
        ))
        self.previewGenerator = previewGenerator
        self.presentationMode = presentationMode
        _selectedColor = .init(initialValue: VaultItemColor.default.color)

        viewModel.startEditing()
    }

    private let toastOptions = SimpleToastOptions(
        hideAfter: 1.5,
        animation: .spring,
        modifierType: .slide
    )

    var body: some View {
        VaultItemDetailView(
            viewModel: viewModel,
            currentError: $currentError,
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation,
            navigationPath: $navigationPath,
            presentationMode: presentationMode
        ) {
            if viewModel.isInEditMode {
                if viewModel.showsKeyEditingFields {
                    keyEditingSection
                }
                nameEditingSection
                descriptionEditingSection
                if viewModel.allTags.isNotEmpty {
                    tagSelectionSection
                }
                passphraseEditingSection
                if viewModel.shouldShowDeleteButton {
                    deleteSection
                }
            } else {
                if case let .editing(code, metadata) = viewModel.mode {
                    codeInformationSection(code: code, metadata: metadata)
                }
            }
        }
        .animation(.easeOut, value: viewModel.editingModel.detail.viewConfig)
        .sheet(item: $modal, onDismiss: nil, content: { item in
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
        })
        .onChange(of: selectedColor.hashValue) { _, _ in
            viewModel.editingModel.detail.color = VaultItemColor(color: selectedColor)
        }
        .onDisappear {
            // Clear the state of the navigation path, if any.
            // This is because of a BUG where (when we use the injected presentationMode to dismiss the navigation
            // stack), launching the navigation stack the next time (to view another code) might have the detail
            // already presented!!!
            //
            // Some weird cache issue or something, but this fixes it.
            navigationPath.removeLast(navigationPath.count)
        }
        .onReceive(pasteboard.didPaste()) {
            isShowingCopyPaste = true
        }
        .simpleToast(isPresented: $isShowingCopyPaste, options: toastOptions, onDismiss: nil) {
            ToastAlertMessageView.copiedToClipboard()
                .padding(.top, 24)
        }
    }

    private var iconHeader: some View {
        VStack(spacing: 8) {
            OTPCodeIconPlaceholderView(
                iconFontSize: viewModel.isInEditMode ? 44 : 22,
                backgroundColor: selectedColor
            )
            .clipShape(Circle())

            ColorPicker(selection: $selectedColor, supportsOpacity: false, label: {
                EmptyView()
            })
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
    }

    private var nameEditingSection: some View {
        Section {
            TextField(
                viewModel.strings.siteNameTitle,
                text: $viewModel.editingModel.detail.issuerTitle
            )
            TextField(text: $viewModel.editingModel.detail.accountNameTitle) {
                Text(viewModel.strings.accountNameExample)
            }
        } header: {
            iconHeader
                .padding(.vertical, viewModel.isInEditMode ? 16 : 0)
        }
    }

    private var descriptionEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .frame(height: 100)
                .keyboardType(.default)
                .listRowInsets(EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16))
        } header: {
            Text(viewModel.strings.descriptionTitle)
        }
    }

    private var keyEditingSection: some View {
        Section {
            TextField(viewModel.strings.inputSecretTitle, text: $viewModel.editingModel.detail.secretBase32String)

            Picker(selection: $viewModel.editingModel.detail.codeType) {
                ForEach(OTPAuthType.Kind.allCases) { authType in
                    Text(viewModel.strings.codeKindTitle(kind: authType))
                        .tag(authType)
                }
            } label: {
                Text(viewModel.strings.inputCodeTypeTitle)
            }

            DisclosureGroup {
                switch viewModel.editingModel.detail.codeType {
                case .totp:
                    Stepper(value: $viewModel.editingModel.detail.totpPeriodLength, in: 1 ... UInt64(Int.max)) {
                        LabeledContent(
                            viewModel.strings.inputTotpPeriodTitle,
                            value: "\(viewModel.editingModel.detail.totpPeriodLength)"
                        )
                    }
                case .hotp:
                    Stepper(value: $viewModel.editingModel.detail.hotpCounterValue, in: 0 ... UInt64(Int.max)) {
                        LabeledContent(
                            viewModel.strings.inputHotpCounterTitle,
                            value: "\(viewModel.editingModel.detail.hotpCounterValue)"
                        )
                    }
                }

                Picker(selection: $viewModel.editingModel.detail.algorithm) {
                    ForEach(OTPAuthAlgorithm.allCases) { algorithm in
                        Text(algorithm.stringValue)
                            .tag(algorithm)
                    }
                } label: {
                    Text(viewModel.strings.inputAlgorithmTitle)
                }

                Stepper(value: $viewModel.editingModel.detail.numberOfDigits, in: 1 ... UInt16.max) {
                    LabeledContent(
                        viewModel.strings.inputNumberOfDigitsTitle,
                        value: "\(viewModel.editingModel.detail.numberOfDigits)"
                    )
                }
            } label: {
                Text(viewModel.strings.advancedSectionTitle)
            }
        } header: {
            OTPKeyValidationView(
                validationState: viewModel.editingModel.detail.$secretBase32String,
                validTitle: viewModel.strings.inputKeyValidTitle,
                invalidTitle: viewModel.strings.inputKeyEmptyTitle,
                errorTitle: viewModel.strings.inputKeyErrorTitle
            )
            .padding()
            .modifier(HorizontallyCenter())
        }
    }

    private func codeInformationSection(code: OTPAuthCode, metadata: VaultItem.Metadata) -> some View {
        Section {
            copyableViewGenerator().makeVaultPreviewView(
                item: .otpCode(code),
                metadata: metadata,
                behaviour: .normal
            )
            .frame(maxWidth: 220)
            .padding(4) // some additional padding because it's bigger
            .padding(.horizontal, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.secondary, lineWidth: 4)
            )
            .padding()
            .modifier(HorizontallyCenter())
            .listRowBackground(EmptyView())
        } footer: {
            VStack(alignment: .center, spacing: 24) {
                if !viewModel.editingModel.detail.description.isBlank {
                    Text(viewModel.editingModel.detail.description)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .font(.callout)
                        .multilineTextAlignment(.leading)

                    Divider()
                }

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
                        ForEach(viewModel.detailMenuItems) { entry in
                            FooterInfoLabel(
                                title: entry.title,
                                detail: entry.detail,
                                systemImageName: entry.systemIconName
                            )
                        }
                    }
                    .font(.footnote)
                }
            }
            .padding(.top, 16)
        }
    }

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

    private var passphraseEditingSection: some View {
        Section {
            Toggle(isOn: $viewModel.editingModel.detail.isLocked) {
                FormRow(
                    image: Image(systemName: viewModel.editingModel.detail.lockState.systemIconName),
                    color: viewModel.editingModel.detail.isLocked ? .red : .green,
                    style: .prominent
                ) {
                    VStack(alignment: .leading) {
                        Text("Lock code")
                            .font(.body)
                        Text("Require authentication to view this code")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
                        Text("Hide this code from being visible in the feed")
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
            Text(viewModel.strings.visibilitySectionTitle)
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

    func copyableViewGenerator() -> VaultItemOnTapDecoratorViewGenerator<PreviewGenerator> {
        VaultItemOnTapDecoratorViewGenerator(generator: previewGenerator) { id in
            if let text = previewGenerator.textToCopyForVaultItem(id: id) {
                pasteboard.copy(text)
            }
        }
    }
}

#Preview {
    OTPCodeDetailView(
        editingExistingCode: .init(
            type: .totp(),
            data: .init(secret: .empty(), accountName: "Test")
        ),
        navigationPath: .constant(.init()),
        dataModel: VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultDeleter: VaultStoreDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        storedMetadata: .init(
            id: .new(),
            created: Date(),
            updated: Date(),
            relativeOrder: .min,
            userDescription: "Description",
            tags: [],
            visibility: .always,
            searchableLevel: .full,
            searchPassphrase: "",
            lockState: .notLocked,
            color: VaultItemColor(color: .green)
        ),
        editor: OTPCodeDetailEditorMock(),
        previewGenerator: VaultItemPreviewViewGeneratorMock(),
        openInEditMode: false,
        presentationMode: nil
    )
    .environment(Pasteboard(
        SystemPasteboardImpl(clock: EpochClockImpl()),
        localSettings: .init(defaults: .init(userDefaults: .standard))
    ))
}
