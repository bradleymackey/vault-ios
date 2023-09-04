import OTPCore
import OTPFeed
import SwiftUI

public struct OTPCodeDetailView<Editor: CodeDetailEditor>: View {
    @ObservedObject public var viewModel: CodeDetailViewModel

    private var editor: Editor
    @StateObject private var editingModel: CodeDetailEditingModel
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    @State private var isSaveError = false

    private struct SaveError: Error, LocalizedError {
        var errorDescription: String? {
            localized(key: "codeDetail.action.save.error.title")
        }
    }

    public init(viewModel: CodeDetailViewModel, editor: Editor) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _editingModel = StateObject(wrappedValue: viewModel.makeEditingViewModel())
        self.editor = editor
    }

    public var body: some View {
        Form {
            codeDetailSection
            descriptionSection
            metadataSection
        }
        .navigationTitle(localized(key: "codeDetail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(editingModel.isDirty)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            if editingModel.isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(viewModel.cancelEditsTitle)
                            .tint(.red)
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if editingModel.isDirty {
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        Text(viewModel.saveEditsTitle)
                            .tint(.accentColor)
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text(viewModel.doneEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }
        }
        .alert(isPresented: $isSaveError, error: SaveError(), actions: { _ in
            Button("OK", role: .cancel) {}
        }, message: { _ in
            Text(localized(key: "codeDetail.action.save.error.description"))
        })
    }

    private func saveChanges() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await editor.update(code: viewModel.storedCode, edits: editingModel.detail)
            dismiss()
        } catch {
            isSaveError = true
        }
    }

    private var iconHeader: some View {
        HStack {
            Spacer()
            CodeIconPlaceholderView(iconFontSize: 22)
                .clipShape(Circle())
            Spacer()
        }
        .padding()
    }

    private var codeDetailSection: some View {
        Section {
            TextField(
                localized(key: "codeDetail.field.siteName.title"),
                text: $editingModel.detail.issuerTitle
            )
            TextField(
                localized(key: "codeDetail.field.accountName.title"),
                text: $editingModel.detail.accountNameTitle
            )
        } header: {
            iconHeader
        }
        .keyboardType(.default)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
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
        }
    }

    private var metadataSection: some View {
        Section {
            Label {
                LabeledContent(viewModel.createdDateTitle, value: viewModel.createdDateValue)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.primary)
            }

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
                        Image(systemName: item.systemIconName)
                            .foregroundColor(.primary)
                    }
                }
            }
        } header: {
            DetailSubtitleView(
                title: localized(key: "codeDetail.metadata.title"),
                subtitle: localized(key: "codeDetail.metadata.subtitle")
            )
            .textCase(.none)
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
    }
}
