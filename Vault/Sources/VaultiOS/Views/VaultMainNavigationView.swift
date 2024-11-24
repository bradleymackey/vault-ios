import SwiftUI
import Toasts
import VaultFeed
import VaultSettings

struct VaultMainNavigationView: View {
    @State var pasteboard: Pasteboard
    @State var localSettings: LocalSettings
    @State var deviceAuthenticationService: DeviceAuthenticationService
    @State var vaultDataModel: VaultDataModel
    @State var injector: VaultInjector
    @Environment(\.presentToast) private var presentToast

    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingCopyPaste = false
    @State private var selectedView: SidebarItem? = .items

    enum SidebarItem: Hashable {
        case items
        case tags
        case backups
        case settings
        case demos
    }

    var body: some View {
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
            let toast = ToastValue(
                icon: Image(systemName: "doc.on.doc.fill"),
                message: localized(key: "code.copyied")
            )
            presentToast(toast)
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
