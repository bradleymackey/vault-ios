import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct OTPCodeDetailView<PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler>: View
    where PreviewGenerator.PreviewItem == VaultItem
{
    @State private var viewModel: OTPCodeDetailViewModel
    private var previewGenerator: PreviewGenerator
    @Binding var navigationPath: NavigationPath
    private var presentationMode: Binding<PresentationMode>?

    init(
        editingExistingCode code: OTPAuthCode,
        navigationPath: Binding<NavigationPath>,
        storedMetadata: StoredVaultItem.Metadata,
        editor: any OTPCodeDetailEditor,
        previewGenerator: PreviewGenerator,
        openInEditMode: Bool,
        presentationMode: Binding<PresentationMode>?
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(mode: .editing(code: code, metadata: storedMetadata), editor: editor))
        self.previewGenerator = previewGenerator
        self.presentationMode = presentationMode

        if openInEditMode {
            viewModel.startEditing()
        }
    }

    init(
        newCodeWithContext initialCode: OTPAuthCode?,
        navigationPath: Binding<NavigationPath>,
        editor: any OTPCodeDetailEditor,
        previewGenerator: PreviewGenerator,
        presentationMode: Binding<PresentationMode>?
    ) {
        _navigationPath = navigationPath
        _viewModel = .init(initialValue: .init(mode: .creating(initialCode: initialCode), editor: editor))
        self.previewGenerator = previewGenerator
        self.presentationMode = presentationMode

        viewModel.startEditing()
    }

    @Environment(Pasteboard.self) private var pasteboard: Pasteboard
    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingCopyPaste = false

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
            if viewModel.isInEditMode, viewModel.showsKeyEditingFields {
                keyEditingSection
            }

            codeNameSection
            if viewModel.isInEditMode {
                accountNameEditingSection
                descriptionEditingSection
            } else if case let .editing(code, metadata) = viewModel.mode {
                metadataSection(code: code, metadata: metadata)
            }
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
        HStack {
            Spacer()
            OTPCodeIconPlaceholderView(iconFontSize: viewModel.isInEditMode ? 44 : 22)
                .clipShape(Circle())
            Spacer()
        }
    }

    private var codeNameSection: some View {
        Section {
            if viewModel.isInEditMode {
                TextField(
                    viewModel.strings.siteNameTitle,
                    text: $viewModel.editingModel.detail.issuerTitle
                )
            } else {
                VStack(alignment: .center, spacing: 2) {
                    Text(viewModel.visibleIssuerTitle)
                        .font(.title.bold())
                        .lineLimit(5)
                    Text(viewModel.editingModel.detail.accountNameTitle)
                        .font(.callout.bold())
                        .lineLimit(2)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .textSelection(.enabled)
                .noListBackground()

                Text(viewModel.editingModel.detail.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .noListBackground()
            }
        } header: {
            iconHeader
                .padding(.vertical, viewModel.isInEditMode ? 16 : 0)
        }
    }

    private var accountNameEditingSection: some View {
        Section {
            TextField(text: $viewModel.editingModel.detail.accountNameTitle) {
                Text(viewModel.strings.accountNameExample)
            }
        } header: {
            Text(viewModel.strings.accountNameTitle)
        }
    }

    private var descriptionEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .frame(height: 100)
                .keyboardType(.default)
        } header: {
            Text(viewModel.strings.descriptionTitle)
        } footer: {
            if viewModel.shouldShowDeleteButton {
                deleteButton
                    .modifier(HorizontallyCenter())
                    .padding()
                    .padding(.vertical, 16)
            }
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

    private func metadataSection(code: OTPAuthCode, metadata: StoredVaultItem.Metadata) -> some View {
        Section {
            ForEach(viewModel.detailMenuItems) { item in
                ForEach(item.entries) { entry in
                    Label {
                        LabeledContent(entry.title, value: entry.detail)
                    } icon: {
                        RowIcon(icon: Image(systemName: entry.systemIconName), color: .accentColor)
                            .foregroundColor(.white)
                    }
                }
            }
        } header: {
            VStack(alignment: .center) {
                copyableViewGenerator().makeVaultPreviewView(
                    item: .otpCode(code),
                    metadata: metadata,
                    behaviour: .normal
                )
                .frame(maxWidth: 200)
                .modifier(OTPCardViewModifier(context: .tertiary))
                .modifier(HorizontallyCenter())
            }
            .textCase(.none)
            .padding(.bottom, 32)
        } footer: {
            VStack(alignment: .leading, spacing: 2) {
                if let createdDateValue = viewModel.createdDateValue {
                    FooterInfoLabel(
                        title: viewModel.strings.createdDateTitle,
                        detail: createdDateValue,
                        systemImageName: "clock.fill"
                    )
                }

                if let updatedDateValue = viewModel.updatedDateValue {
                    FooterInfoLabel(
                        title: viewModel.strings.updatedDateTitle,
                        detail: updatedDateValue,
                        systemImageName: "clock.arrow.2.circlepath"
                    )
                }
            }
            .font(.footnote)
            .padding(.top, 8)
        }
    }

    private var deleteButton: some View {
        Button {
            isShowingDeleteConfirmation = true
        } label: {
            ItemDeleteLabel()
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

struct OTPCodeDetailView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()

    static var previews: some View {
        OTPCodeDetailView(
            editingExistingCode: .init(
                type: .totp(),
                data: .init(secret: .empty(), accountName: "Test")
            ),
            navigationPath: .constant(.init()),
            storedMetadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: "Description"
            ),
            editor: StubEditor(),
            previewGenerator: VaultItemPreviewViewGeneratorMock(),
            openInEditMode: false,
            presentationMode: nil
        )
    }

    class StubEditor: OTPCodeDetailEditor {
        func createCode(initialEdits _: OTPCodeDetailEdits) async throws {
            // noop
        }

        func updateCode(id _: UUID, item _: OTPAuthCode, edits _: OTPCodeDetailEdits) async throws {
            // noop
        }

        func deleteCode(id _: UUID) async throws {
            // noop
        }
    }
}
