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

    init(
        code: OTPAuthCode,
        storedMetadata: StoredVaultItem.Metadata,
        editor: any OTPCodeDetailEditor,
        previewGenerator: PreviewGenerator
    ) {
        _viewModel = .init(initialValue: .init(storedCode: code, storedMetadata: storedMetadata, editor: editor))
        self.previewGenerator = previewGenerator
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
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation
        ) {
            codeDetailSection
            if viewModel.isInEditMode {
                descriptionEditingSection
            } else {
                descriptionSection
                metadataSection
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

    private var codeDetailSection: some View {
        Section {
            if viewModel.isInEditMode {
                codeDetailContentEditing
            } else {
                codeDetailContent
            }
        } header: {
            iconHeader
                .padding(.vertical, viewModel.isInEditMode ? 16 : 0)
        } footer: {
            if !viewModel.isInEditMode {
                VStack(alignment: .center) {
                    copyableViewGenerator().makeVaultPreviewView(
                        item: .otpCode(viewModel.storedCode),
                        metadata: viewModel.storedMetdata,
                        behaviour: .normal
                    )
                    .frame(maxWidth: 200)
                    .modifier(OTPCardViewModifier(context: .tertiary))
                    .modifier(HorizontallyCenter())
                    .padding(.top, 16)
                }
                .textCase(.none)
            }
        }
        .keyboardType(.default)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
    }

    private var codeDetailContent: some View {
        EmptyView()
    }

    @ViewBuilder
    private var codeDetailContentEditing: some View {
        TextField(
            viewModel.strings.siteNameTitle,
            text: $viewModel.editingModel.detail.issuerTitle
        )
        TextField(
            viewModel.strings.accountNameTitle,
            text: $viewModel.editingModel.detail.accountNameTitle
        )
    }

    private var descriptionEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .frame(height: 200)
                .keyboardType(.default)
        } header: {
            Text(viewModel.strings.descriptionTitle)
        } footer: {
            deleteButton
                .modifier(HorizontallyCenter())
                .padding()
                .padding(.vertical, 16)
        }
    }

    private var descriptionSection: some View {
        Section {
            Text(viewModel.editingModel.detail.description)
        } header: {
            Text(viewModel.strings.descriptionTitle)
        }
    }

    private var metadataSection: some View {
        Section {
            ForEach(viewModel.detailMenuItems) { item in
                DisclosureGroup {
                    ForEach(item.entries) { entry in
                        Label {
                            LabeledContent(entry.title, value: entry.detail)
                        } icon: {
                            RowIcon(icon: Image(systemName: entry.systemIconName), color: .secondary)
                                .foregroundColor(.white)
                        }
                    }
                } label: {
                    Label {
                        Text(item.title)
                    } icon: {
                        RowIcon(icon: Image(systemName: item.systemIconName), color: .blue)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.vertical, 2)

        } footer: {
            VStack(alignment: .leading, spacing: 2) {
                FooterInfoLabel(
                    title: viewModel.strings.createdDateTitle,
                    detail: viewModel.createdDateValue,
                    systemImageName: "clock.fill"
                )

                if viewModel.updatedDateValue != viewModel.createdDateValue {
                    FooterInfoLabel(
                        title: viewModel.strings.updatedDateTitle,
                        detail: viewModel.updatedDateValue,
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
            code: .init(
                type: .totp(),
                data: .init(secret: .empty(), accountName: "Test")
            ),
            storedMetadata: .init(
                id: UUID(),
                created: Date(),
                updated: Date(),
                userDescription: "Description"
            ),
            editor: StubEditor(),
            previewGenerator: VaultItemPreviewViewGeneratorMock()
        )
    }

    class StubEditor: OTPCodeDetailEditor {
        func update(id _: UUID, item _: OTPAuthCode, edits _: OTPCodeDetailEdits) async throws {
            // noop
        }

        func deleteCode(id _: UUID) async throws {
            // noop
        }
    }
}
