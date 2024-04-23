import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct SecureNoteDetailView: View {
    @State private var viewModel: SecureNoteDetailViewModel

    init(note: SecureNote, storedMetadata: StoredVaultItem.Metadata, editor: any SecureNoteDetailEditor) {
        _viewModel = .init(initialValue: .init(storedNote: note, storedMetadata: storedMetadata, editor: editor))
    }

    @State private var currentError: (any Error)?
    @State private var isShowingDeleteConfirmation = false
    @State private var textEditingModal: TextEditingModal?

    enum TextEditingModal: String, Identifiable {
        case title
        case description
        case content

        var id: some Hashable { rawValue }
    }

    var body: some View {
        VaultItemDetailView(
            viewModel: viewModel,
            currentError: $currentError,
            isShowingDeleteConfirmation: $isShowingDeleteConfirmation
        ) {
            if viewModel.isInEditMode {
                noteTitleEditingSection
                noteDescriptionEditingSection
                noteContentsEditingSection
            } else {
                noteDetailContent
                noteContentsSection
            }
        }
        .sheet(item: $textEditingModal) {
            // ignore
        } content: { item in
            switch item {
            case .title:
                NavigationView {
                    TextEditingView(
                        text: $viewModel.editingModel.detail.title,
                        font: .systemFont(ofSize: 16, weight: .regular)
                    )
                    .navigationTitle(Text(viewModel.strings.noteTitle))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                textEditingModal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            case .description:
                NavigationView {
                    TextEditingView(
                        text: $viewModel.editingModel.detail.description,
                        font: .systemFont(ofSize: 16, weight: .regular)
                    )
                    .navigationTitle(Text(viewModel.strings.descriptionTitle))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                textEditingModal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            case .content:
                NavigationView {
                    TextEditingView(
                        text: $viewModel.editingModel.detail.contents,
                        font: .monospacedSystemFont(ofSize: 16, weight: .regular)
                    )
                    .navigationTitle(Text(viewModel.strings.descriptionTitle))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                textEditingModal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Title & Description

    @ViewBuilder
    private var noteDetailContent: some View {
        VStack(alignment: .center, spacing: 4) {
            if viewModel.editingModel.detail.title.isNotEmpty {
                Text(viewModel.editingModel.detail.title)
                    .font(.title.bold())
                    .textSelection(.enabled)
            }
        }
        .lineLimit(5)
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
            .textSelection(.enabled)
        }
    }

    private var noteTitleEditingSection: some View {
        Section {
            TextField(text: $viewModel.editingModel.detail.title) {
                Text(viewModel.strings.noteTitleExample)
            }
        } header: {
            Text(viewModel.strings.noteTitle)
        }
    }

    private var noteDescriptionEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.description)
                .font(.callout)
                .frame(minHeight: 60)
        } header: {
            Text(viewModel.strings.noteDescription)
        }
    }

    // MARK: Contents

    private var noteContentsSection: some View {
        Section {
            SelectableText(
                viewModel.editingModel.detail.contents,
                font: .monospacedSystemFont(ofSize: 16, weight: .regular)
            )
            .frame(minHeight: 250, alignment: .top)
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
            .transition(.opacity)
        }
    }

    private var noteContentsEditingSection: some View {
        Section {
            TextEditor(text: $viewModel.editingModel.detail.contents)
                .font(.callout)
                .fontDesign(.monospaced)
                .frame(minHeight: 250)
        } header: {
            Text(viewModel.strings.noteContentsTitle)
        } footer: {
            deleteButton
                .modifier(HorizontallyCenter())
                .padding()
                .padding(.vertical, 16)
                .transition(.opacity)
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
