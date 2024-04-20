import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
public struct OTPCodeDetailView<PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler>: View
    where PreviewGenerator.PreviewItem == VaultItem
{
    @Bindable public var viewModel: OTPCodeDetailViewModel

    @Environment(Pasteboard.self) var pasteboard: Pasteboard
    @Environment(\.dismiss) var dismiss
    @State private var isError = false
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
        Form {
            codeDetailSection
            if viewModel.isInEditMode {
                descriptionSection
            }
            if !viewModel.isInEditMode {
                codePreviewSection
                metadataSection
            }
        }
        .navigationTitle(viewModel.strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.editingModel.isDirty)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeOut, value: viewModel.isInEditMode)
        .onReceive(viewModel.isFinishedPublisher()) {
            dismiss()
        }
        .onReceive(viewModel.didEncounterErrorPublisher()) { error in
            currentError = error
            isError = true
        }
        .confirmationDialog(
            viewModel.strings.deleteConfirmTitle,
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(viewModel.strings.deleteCodeTitle, role: .destructive) {
                Task { await viewModel.deleteCode() }
            }
        } message: {
            Text(viewModel.strings.deleteConfirmSubtitle)
        }
        .alert(localized(key: "action.error.title"), isPresented: $isError, presenting: currentError) { _ in
            Button(localized(key: "action.error.confirm.title"), role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .onReceive(pasteboard.didPaste()) {
            isShowingCopyPaste = true
        }
        .simpleToast(isPresented: $isShowingCopyPaste, options: toastOptions, onDismiss: nil) {
            ToastAlertMessageView.copiedToClipboard()
                .padding(.top, 24)
        }
        .toolbar {
            if viewModel.editingModel.isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.done()
                    } label: {
                        Text(viewModel.strings.cancelEditsTitle)
                            .tint(.red)
                    }
                }
            } else if !viewModel.isInEditMode {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.startEditing()
                    } label: {
                        Text(viewModel.strings.startEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }

            if viewModel.editingModel.isDirty {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.saveChanges() }
                    } label: {
                        Text(viewModel.strings.saveEditsTitle)
                            .tint(.accentColor)
                    }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.done()
                    } label: {
                        Text(viewModel.strings.doneEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }
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
            if !viewModel.editingModel.detail.issuerTitle.isEmpty {
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
        .listRowInsets(.none)
        .listRowBackground(EmptyView())
        .listRowSeparator(.hidden)

        if !viewModel.editingModel.detail.description.isEmpty {
            VStack(alignment: .center) {
                Text(viewModel.editingModel.detail.description)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(EmptyView())
            .listRowSeparator(.hidden)
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

    private var codePreviewSection: some View {
        Section {}
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
                .padding(.vertical, 24)
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
