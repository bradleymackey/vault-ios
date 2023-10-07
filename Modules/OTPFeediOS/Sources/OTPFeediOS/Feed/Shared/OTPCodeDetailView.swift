import OTPCore
import OTPFeed
import OTPUI
import SwiftUI

public struct OTPCodeDetailView<Editor: CodeDetailEditor>: View {
    // TODO: move more logic to the view model, and test it!
    @ObservedObject public var viewModel: CodeDetailViewModel

    private var editor: Editor
    @State private var editingModel: CodeDetailEditingModel
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    @State private var isError = false
    @State private var currentError: OperationError?
    @State private var isInEditMode = false
    @State private var isShowingDeleteConfirmation = false

    enum OperationError: String, Identifiable {
        case save
        case delete

        var description: String {
            switch self {
            case .save:
                return localized(key: "codeDetail.action.save.error.description")
            case .delete:
                return localized(key: "codeDetail.action.delete.error.description")
            }
        }

        var id: some Hashable {
            rawValue
        }
    }

    public init(viewModel: CodeDetailViewModel, editor: Editor) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _editingModel = State(initialValue: viewModel.makeEditingViewModel())
        self.editor = editor
    }

    public var body: some View {
        Form {
            codeDetailSection
            if isInEditMode {
                descriptionSection
            }
            metadataSection
        }
        .navigationTitle(localized(key: "codeDetail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(editingModel.isDirty)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeOut, value: isInEditMode)
        .confirmationDialog(
            localized(key: "codeDetail.action.delete.confirm.title"),
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(localized(key: "codeDetail.action.delete.entity.title"), role: .destructive) {
                Task { await deleteCode() }
            }
        } message: {
            Text(localized(key: "codeDetail.action.delete.confirm.subtitle"))
        }
        .alert(localized(key: "codeDetail.action.error.title"), isPresented: $isError, presenting: currentError) { _ in
            Button(localized(key: "codeDetail.action.error.confirm.title"), role: .cancel) {}
        } message: { error in
            Text(error.description)
        }
        .toolbar {
            if editingModel.isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        cancelButtonPressed()
                    } label: {
                        Text(viewModel.cancelEditsTitle)
                            .tint(.red)
                    }
                }
            } else if !isInEditMode {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isInEditMode = true
                    } label: {
                        Text(viewModel.startEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }

            if editingModel.isDirty {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        Text(viewModel.saveEditsTitle)
                            .tint(.accentColor)
                    }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        doneButtonPressed()
                    } label: {
                        Text(viewModel.doneEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }
        }
    }

    private func cancelButtonPressed() {
        isInEditMode = false
        editingModel.restoreInitialState()
    }

    private func doneButtonPressed() {
        if isInEditMode {
            isInEditMode = false
        } else {
            dismiss()
        }
    }

    private func saveChanges() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await editor.update(code: viewModel.storedCode, edits: editingModel.detail)
            isInEditMode = false
            editingModel.didPersist()
        } catch {
            currentError = .save
            isError = true
        }
    }

    private func deleteCode() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await editor.deleteCode(id: viewModel.storedCode.id)
            dismiss()
        } catch {
            currentError = .delete
            isError = true
        }
    }

    private var iconHeader: some View {
        HStack {
            Spacer()
            CodeIconPlaceholderView(iconFontSize: 22)
                .clipShape(Circle())
            Spacer()
        }
    }

    private var codeDetailSection: some View {
        Section {
            if isInEditMode {
                codeDetailContentEditing
            } else {
                codeDetailContent
            }
        } header: {
            iconHeader
                .padding(.vertical, isInEditMode ? 16 : 0)
        }
        .keyboardType(.default)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
    }

    @ViewBuilder
    private var codeDetailContent: some View {
        VStack(alignment: .center, spacing: 4) {
            if !editingModel.detail.issuerTitle.isEmpty {
                Text(editingModel.detail.issuerTitle)
                    .font(.title.bold())
            }
            Text(editingModel.detail.accountNameTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .lineLimit(2)
        .multilineTextAlignment(.center)

        .frame(maxWidth: .infinity)
        .listRowInsets(.none)
        .listRowBackground(EmptyView())
        .listRowSeparator(.hidden)

        if !editingModel.detail.description.isEmpty {
            VStack(alignment: .center) {
                Text(editingModel.detail.description)
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
            localized(key: "codeDetail.field.siteName.title"),
            text: $editingModel.detail.issuerTitle
        )
        TextField(
            localized(key: "codeDetail.field.accountName.title"),
            text: $editingModel.detail.accountNameTitle
        )
    }

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $editingModel.detail.description)
                .frame(height: 200)
                .keyboardType(.default)
        } header: {
            DetailSubtitleView(
                title: localized(key: "codeDetail.description.title"),
                subtitle: localized(key: "codeDetail.description.subtitle")
            )
            .textCase(.none)
            .padding(.vertical, 8)
        }
    }

    private var metadataSection: some View {
        Section {
            Label {
                LabeledContent(viewModel.createdDateTitle, value: viewModel.createdDateValue)
            } icon: {
                RowIcon(icon: Image(systemName: "clock.fill"), color: .green)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 2)

            ForEach(viewModel.detailMenuItems) { item in
                DisclosureGroup {
                    ForEach(item.entries) { entry in
                        Label {
                            LabeledContent(entry.title, value: entry.detail)
                        } icon: {
                            Image(systemName: entry.systemIconName)
                                .foregroundColor(.primary)
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
            DetailSubtitleView(
                title: localized(key: "codeDetail.metadata.title"),
                subtitle: localized(key: "codeDetail.metadata.subtitle")
            )
            .textCase(.none)
            .padding(.vertical, 8)
        } footer: {
            HStack {
                Spacer()
                if isInEditMode {
                    deleteButton
                }
                Spacer()
            }
            .padding()
            .padding(.vertical, 16)
        }
    }

    private var deleteButton: some View {
        Button {
            isShowingDeleteConfirmation = true
        } label: {
            CodeDeleteLabel()
        }
    }
}

struct OTPCodeDetailView_Previews: PreviewProvider {
    private static let codeRenderer = OTPCodeRendererMock()

    static var previews: some View {
        OTPCodeDetailView(
            viewModel: CodeDetailViewModel(
                storedCode: .init(
                    id: UUID(),
                    created: Date(),
                    updated: Date(),
                    userDescription: "Description",
                    code: .init(
                        type: .totp(),
                        data: .init(secret: .empty(), accountName: "Test")
                    )
                )
            ),
            editor: StubEditor()
        )
    }

    class StubEditor: ObservableObject, CodeDetailEditor {
        func update(code _: StoredOTPCode, edits _: CodeDetailEdits) async throws {
            // noop
        }

        func deleteCode(id _: UUID) async throws {
            // noop
        }
    }
}
