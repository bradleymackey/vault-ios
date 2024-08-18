import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultSettings

@MainActor
struct VaultListView<
    Generator: VaultItemPreviewViewGenerator & VaultItemPreviewActionHandler & VaultItemCopyActionHandler
>: View
    where Generator.PreviewItem == VaultItem.Payload
{
    var localSettings: LocalSettings
    var viewGenerator: Generator

    init(localSettings: LocalSettings, viewGenerator: Generator) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
    }

    @Environment(VaultDataModel.self) private var dataModel
    @Environment(Pasteboard.self) var pasteboard: Pasteboard
    @State private var isEditing = false
    @State private var isShowingEditSheet = false
    @State private var modal: Modal?
    @State private var navigationPath = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase

    enum Modal: Hashable, IdentifiableSelf {
        case detail(Identifier<VaultItem>, VaultItem)
        case creatingItem(CreatingItem)
    }

    var body: some View {
        VaultItemFeedView(
            localSettings: localSettings,
            viewGenerator: interactableViewGenerator(),
            isEditing: $isEditing,
            gridSpacing: 12
        )
        .toolbar {
            if dataModel.items.isNotEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEditSheet.toggle()
                    } label: {
                        Label("Edit", systemImage: "ellipsis.circle")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        modal = .creatingItem(.otpCode)
                    } label: {
                        LabeledContent {
                            Text("Code")
                        } label: {
                            Image(systemName: "qrcode")
                        }
                    }

                    Button {
                        modal = .creatingItem(.secureNote)
                    } label: {
                        LabeledContent {
                            Text("Note")
                        } label: {
                            Image(systemName: "text.alignleft")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog("Items", isPresented: $isShowingEditSheet, actions: {
            Button {
                isEditing = true
            } label: {
                Label("Edit Items", systemImage: "pencil")
            }

            Button("Cancel", role: .cancel) {}
        })
        .sheet(item: $modal, onDismiss: nil) { visible in
            switch visible {
            case let .detail(_, storedCode):
                NavigationStack(path: $navigationPath) {
                    VaultDetailEditView(
                        storedItem: storedCode,
                        previewGenerator: viewGenerator,
                        openInEditMode: isEditing,
                        navigationPath: $navigationPath
                    )
                }
            case let .creatingItem(creatingItem):
                NavigationStack(path: $navigationPath) {
                    VaultDetailCreateView(
                        creatingItem: creatingItem,
                        previewGenerator: viewGenerator,
                        navigationPath: $navigationPath
                    )
                }
            }
        }
        .onChange(of: modal) { _, newValue in
            // When the detail modal is dismissed, exit editing mode.
            if newValue == nil { isEditing = false }
        }
        .onChange(of: scenePhase) { _, newValue in
            viewGenerator.scenePhaseDidChange(to: newValue)
        }
        .onAppear {
            viewGenerator.didAppear()
        }
    }

    func interactableViewGenerator()
        -> VaultItemOnTapDecoratorViewGenerator<Generator>
    {
        VaultItemOnTapDecoratorViewGenerator(generator: viewGenerator) { id in
            if isEditing {
                guard let item = dataModel.code(id: id) else { return }
                modal = .detail(id, item)
            } else if let previewAction = viewGenerator.previewActionForVaultItem(id: id) {
                switch previewAction {
                case let .copyText(text):
                    pasteboard.copy(text)
                case let .openItemDetail(id):
                    guard let item = dataModel.code(id: id) else { return }
                    modal = .detail(id, item)
                }
            }
        }
    }
}
