import SwiftUI
import Toasts
import VaultFeed
import VaultSettings

/// Entrypoint scene for the vault app.
@MainActor
public struct VaultMainScene: Scene {
    @State private var pasteboard: Pasteboard = VaultRoot.pasteboard
    @State private var localSettings: LocalSettings = VaultRoot.localSettings
    @State private var deviceAuthenticationService = VaultRoot.deviceAuthenticationService
    @State private var vaultDataModel: VaultDataModel = VaultRoot.vaultDataModel
    @State private var injector: VaultInjector = VaultRoot.vaultInjector

    public init() {
        UITextView.appearance().textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    public var body: some Scene {
        WindowGroup {
            VaultMainNavigationView(
                pasteboard: pasteboard,
                localSettings: localSettings,
                deviceAuthenticationService: deviceAuthenticationService,
                vaultDataModel: vaultDataModel,
                injector: injector,
            )
            .installToast(position: .top)
        }
    }
}
