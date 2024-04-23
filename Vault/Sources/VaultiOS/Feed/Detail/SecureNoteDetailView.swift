import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct SecureNoteDetailView: View {
    @Bindable var viewModel: SecureNoteDetailViewModel

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
                noteDetailContentEditing
                noteDetailEditingSection
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
        }
    }

    private var noteDetailContentEditing: some View {
        Section {
            Text(viewModel.editingModel.detail.title)
            Button {
                textEditingModal = .title
            } label: {
                Text(viewModel.strings.startEditingTitle)
            }
        } header: {
            Text(viewModel.strings.noteTitle)
        }
    }

    private var noteDetailEditingSection: some View {
        Section {
            Text(viewModel.editingModel.detail.description)
            Button {
                textEditingModal = .description
            } label: {
                Text(viewModel.strings.startEditingTitle)
            }
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
            .textSelection(.enabled)
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
            Text(viewModel.editingModel.detail.contents)
                .textSelection(.enabled)
                .font(.callout)
                .fontDesign(.monospaced)
            Button {
                textEditingModal = .content
            } label: {
                Text(viewModel.strings.startEditingTitle)
            }
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
