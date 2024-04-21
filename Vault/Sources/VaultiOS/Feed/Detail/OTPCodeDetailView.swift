import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
public struct OTPCodeDetailView<PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler>: View
    where PreviewGenerator.PreviewItem == VaultItem
{
    @Bindable public var viewModel: OTPCodeDetailViewModel

    @Environment(Pasteboard.self) private var pasteboard: Pasteboard
    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingCopyPaste = false
    private var previewGenerator: PreviewGenerator

    private let toastOptions = SimpleToastOptions(
        hideAfter: 1.5,
        animation: .spring,
        modifierType: .slide
    )

    public init(viewModel: OTPCodeDetailViewModel, previewGenerator: PreviewGenerator) {
        self.viewModel = viewModel
        self.previewGenerator = previewGenerator
    }

    public var body: some View {
        VaultItemDetailView(
            viewModel: viewModel,
            currentError: $currentError,
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation
        ) {
            codeDetailSection
            if viewModel.isInEditMode {
                descriptionSection
            }
            if !viewModel.isInEditMode {
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
        }
        .keyboardType(.default)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
    }

    @ViewBuilder
    private var codeDetailContent: some View {
        VStack(alignment: .center, spacing: 4) {
            if viewModel.editingModel.detail.issuerTitle.isNotEmpty {
                Text(viewModel.editingModel.detail.issuerTitle)
                    .font(.title.bold())
            }
            Text(viewModel.editingModel.detail.accountNameTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .lineLimit(2)
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

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .frame(height: 200)
                .keyboardType(.default)
        } header: {
            DetailSubtitleView(
                title: viewModel.strings.descriptionTitle,
                subtitle: viewModel.strings.descriptionSubtitle
            )
            .textCase(.none)
            .padding(.vertical, 8)
        } footer: {
            deleteButton
                .modifier(HorizontallyCenter())
                .padding()
                .padding(.vertical, 16)
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

        } header: {
            VStack(alignment: .center) {
                copyableViewGenerator().makeVaultPreviewView(
                    item: .otpCode(viewModel.storedCode),
                    metadata: viewModel.storedMetdata,
                    behaviour: .normal
                )
                .frame(maxWidth: 200)
                .modifier(OTPCardViewModifier(context: .tertiary))
                .modifier(HorizontallyCenter())
                .padding(.bottom, 24)
            }
            .textCase(.none)
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
            viewModel: OTPCodeDetailViewModel(
                storedCode: .init(
                    type: .totp(),
                    data: .init(secret: .empty(), accountName: "Test")
                ),
                storedMetadata: .init(
                    id: UUID(),
                    created: Date(),
                    updated: Date(),
                    userDescription: "Description"
                ),
                editor: StubEditor()
            ),
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
