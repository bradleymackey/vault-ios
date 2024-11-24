import SimpleToast
import SwiftUI
import VaultFeed
import VaultSettings

/// Entrypoint scene for the vault app.
@MainActor
public struct VaultMainScene: Scene {
    @Environment(\.scenePhase) private var scenePhase
    @State private var pasteboard: Pasteboard = VaultRoot.pasteboard
    @State private var localSettings: LocalSettings = VaultRoot.localSettings
    @State private var deviceAuthenticationService = VaultRoot.deviceAuthenticationService
    @State private var vaultDataModel: VaultDataModel = VaultRoot.vaultDataModel
    @State private var injector: VaultInjector = VaultRoot.vaultInjector

    @State private var isShowingCopyPaste = false
    @State private var selectedView: SidebarItem? = .items

    enum SidebarItem: Hashable {
        case items
        case tags
        case backups
        case settings
        case demos
    }

    private let toastOptions = SimpleToastOptions(
        hideAfter: 1.5,
        animation: .spring,
        modifierType: .slide
    )

    public init() {
        UITextView.appearance().textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    public var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(selection: $selectedView) {
                    Section {
                        NavigationLink(value: SidebarItem.items) {
                            Label("Items", systemImage: "key.horizontal.fill")
                        }
                        NavigationLink(value: SidebarItem.tags) {
                            Label("Tags", systemImage: "tag.fill")
                        }
                    }

                    Section {
                        NavigationLink(value: SidebarItem.backups) {
                            Label("Backups", systemImage: "doc.on.doc.fill")
                        }
                        NavigationLink(value: SidebarItem.settings) {
                            Label("Settings", systemImage: "gear")
                        }
                    }

                    #if DEBUG
                    Section {
                        NavigationLink(value: SidebarItem.demos) {
                            Label("Developer", systemImage: "hammer.fill")
                        }
                        .tint(.purple)
                    }
                    #endif
                }
                .navigationTitle("Vault")
                .listStyle(.sidebar)
            } detail: {
                // Show the selected view in the detail area
                switch selectedView {
                case .items:
                    VaultListView(
                        localSettings: localSettings,
                        viewGenerator: VaultRoot.genericVaultItemPreviewViewGenerator,
                        copyActionHandler: VaultRoot.vaultItemCopyHandler,
                        previewActionHandler: VaultRoot.vaultItemPreviewActionHandler
                    )
                    .navigationBarTitleDisplayMode(.inline)
                case .tags:
                    NavigationStack {
                        VaultTagFeedView(viewModel: .init())
                    }
                case .settings:
                    NavigationStack {
                        VaultSettingsView(viewModel: SettingsViewModel(), localSettings: localSettings)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                case .backups:
                    NavigationStack {
                        BackupView()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                case .demos:
                    NavigationStack {
                        DeveloperToolsHomeView()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                case .none:
                    Text("Select an option from the sidebar")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("")
                }
            }
            .onReceive(pasteboard.didPaste()) {
                isShowingCopyPaste = true
            }
            .simpleToast(isPresented: $isShowingCopyPaste, options: toastOptions, onDismiss: nil) {
                ToastAlertMessageView.copiedToClipboard()
                    .padding(.top, 24)
            }
            .task {
                await vaultDataModel.setup()
            }
            .environment(pasteboard)
            .environment(deviceAuthenticationService)
            .environment(vaultDataModel)
            .environment(injector)
            .onChange(of: scenePhase) { _, newValue in
                switch newValue {
                case .background:
                    vaultDataModel.purgeSensitiveData()
                case .active, .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
