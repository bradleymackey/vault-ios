import Combine
import SwiftUI
import VaultFeed
import VaultSettings

@MainActor
struct VaultListView<
    Generator: VaultItemPreviewViewGenerator<VaultItem.Payload>
>: View {
    var localSettings: LocalSettings
    var viewGenerator: Generator
    var copyActionHandler: any VaultItemCopyActionHandler
    var previewActionHandler: any VaultItemPreviewActionHandler
    let openDetailSubject = PassthroughSubject<VaultItem, Never>()

    init(
        localSettings: LocalSettings,
        viewGenerator: Generator,
        copyActionHandler: any VaultItemCopyActionHandler,
        previewActionHandler: any VaultItemPreviewActionHandler
    ) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
        self.copyActionHandler = copyActionHandler
        self.previewActionHandler = previewActionHandler
    }

    @Environment(VaultDataModel.self) private var dataModel
    @Environment(Pasteboard.self) var pasteboard: Pasteboard
    @Environment(DeviceAuthenticationService.self) var authenticationService
    @State private var vaultItemFeedState = VaultItemFeedState()
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
            state: vaultItemFeedState,
            gridSpacing: 12
        )
        .toolbar {
            if vaultItemFeedState.isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vaultItemFeedState.isEditing = false
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }

            } else {
                if dataModel.items.isNotEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingEditSheet.toggle()
                        } label: {
                            Label("Edit", systemImage: "ellipsis")
                        }
                        .confirmationDialog("Items", isPresented: $isShowingEditSheet, actions: {
                            Button {
                                vaultItemFeedState.isEditing = true
                            } label: {
                                Label("Edit Items", systemImage: "pencil")
                            }

                            Button("Cancel", role: .cancel) {}
                        })
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
        }
        .sheet(item: $modal, onDismiss: nil) { visible in
            switch visible {
            case let .detail(_, storedCode):
                NavigationStack(path: $navigationPath) {
                    VaultDetailEditView(
                        storedItem: storedCode,
                        previewGenerator: viewGenerator,
                        copyActionHandler: copyActionHandler,
                        openInEditMode: vaultItemFeedState.isEditing,
                        openDetailSubject: openDetailSubject,
                        navigationPath: $navigationPath
                    )
                }
            case let .creatingItem(creatingItem):
                NavigationStack(path: $navigationPath) {
                    VaultDetailCreateView(
                        creatingItem: creatingItem,
                        previewGenerator: viewGenerator,
                        copyActionHandler: copyActionHandler,
                        navigationPath: $navigationPath
                    )
                }
            }
        }
        .onReceive(openDetailSubject, perform: { item in
            modal = .detail(item.id, item)
        })
        .onChange(of: modal) { _, newValue in
            // When the detail modal is dismissed, exit editing mode.
            if newValue == nil { vaultItemFeedState.isEditing = false }
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
            if vaultItemFeedState.isEditing {
                guard let item = dataModel.code(id: id) else { return }
                modal = .detail(id, item)
            } else if let previewAction = previewActionHandler.previewActionForVaultItem(id: id) {
                switch previewAction {
                case let .copyText(copyAction):
                    if copyAction.requiresAuthenticationToCopy {
                        let result = try await authenticationService
                            .authenticate(reason: "Authenticate to copy locked data")
                        guard result == .success(.authenticated) else { return }
                    }
                    pasteboard.copy(copyAction.text)
                case let .openItemDetail(id):
                    guard let item = dataModel.code(id: id) else { return }
                    modal = .detail(id, item)
                }
            }
        }
    }
}
