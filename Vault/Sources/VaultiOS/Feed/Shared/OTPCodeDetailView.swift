import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
public struct OTPCodeDetailView: View {
    @Bindable public var viewModel: OTPCodeDetailViewModel

    @Environment(\.dismiss) var dismiss
    @State private var isError = false
    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false

    public init(viewModel: OTPCodeDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            codeDetailSection
            if viewModel.isInEditMode {
                descriptionSection
            }
            metadataSection
        }
        .navigationTitle(localized(key: "codeDetail.title"))
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
            localized(key: "codeDetail.action.delete.confirm.title"),
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(localized(key: "codeDetail.action.delete.entity.title"), role: .destructive) {
                Task { await viewModel.deleteCode() }
            }
        } message: {
            Text(localized(key: "codeDetail.action.delete.confirm.subtitle"))
        }
        .alert(localized(key: "codeDetail.action.error.title"), isPresented: $isError, presenting: currentError) { _ in
            Button(localized(key: "codeDetail.action.error.confirm.title"), role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .toolbar {
            if viewModel.editingModel.isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.done()
                    } label: {
                        Text(viewModel.cancelEditsTitle)
                            .tint(.red)
                    }
                }
            } else if !viewModel.isInEditMode {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.startEditing()
                    } label: {
                        Text(viewModel.startEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }

            if viewModel.editingModel.isDirty {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.saveChanges() }
                    } label: {
                        Text(viewModel.saveEditsTitle)
                            .tint(.accentColor)
                    }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.done()
                    } label: {
                        Text(viewModel.doneEditingTitle)
                            .tint(.accentColor)
                    }
                }
            }
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
            localized(key: "codeDetail.field.siteName.title"),
            text: $viewModel.editingModel.detail.issuerTitle
        )
        TextField(
            localized(key: "codeDetail.field.accountName.title"),
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
                if viewModel.isInEditMode {
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
            ItemDeleteLabel()
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
            )
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
