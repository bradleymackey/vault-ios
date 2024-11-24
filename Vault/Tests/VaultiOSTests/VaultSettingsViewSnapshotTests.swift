import Foundation
import TestHelpers
import Testing
import VaultFeed
import VaultSettings
@testable import VaultiOS

@MainActor
struct VaultSettingsViewSnapshotTests {
    @Test
    func layout() throws {
        let dataModel = anyVaultDataModel()
        let localSettings = try LocalSettings(defaults: .nonPersistent())
        let view = VaultSettingsView(viewModel: .init(), localSettings: localSettings)
            .environment(dataModel)
            .environment(DeviceAuthenticationService(policy: .alwaysDeny))
            .framedForTest(height: 600)

        assertSnapshot(of: view, as: .image)
    }
}
