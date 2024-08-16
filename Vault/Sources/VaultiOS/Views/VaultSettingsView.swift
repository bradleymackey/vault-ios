import SwiftUI
import VaultSettings

struct VaultSettingsView: View {
    var viewModel: SettingsViewModel
    var localSettings: LocalSettings

    var body: some View {
        SettingsHomeView(viewModel: viewModel, localSettings: localSettings)
    }
}
