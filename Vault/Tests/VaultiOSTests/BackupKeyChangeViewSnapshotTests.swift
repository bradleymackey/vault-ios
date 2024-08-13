import Foundation
import SwiftUI
import TestHelpers
import VaultSettings
import XCTest
@testable import VaultFeed
@testable import VaultiOS

final class BackupKeyChangeViewSnapshotTests: XCTestCase {
    override func setUp() {
//        isRecording = true
    }

    @MainActor
    func test_layout() async {
        let store = BackupPasswordStoreMock()
        let viewModel = BackupKeyChangeViewModel(store: store, deriverFactory: ApplicationKeyDeriverFactoryImpl())
        let sut = BackupKeyChangeView(viewModel: viewModel)

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_layoutAuthenticated() async {
        let store = BackupPasswordStoreMock()
        let viewModel = BackupKeyChangeViewModel(store: store, deriverFactory: ApplicationKeyDeriverFactoryImpl())
        viewModel.permissionState = .allowed
        let sut = BackupKeyChangeView(viewModel: viewModel)

        await snapshotScenarios(view: sut)
    }
}

// MARK: - Helpers

extension BackupKeyChangeViewSnapshotTests {
    @MainActor
    private func snapshotScenarios(
        view: some View,
        deviceAuthenticationPolicy: some DeviceAuthenticationPolicy = DeviceAuthenticationPolicyAlwaysAllow(),
        testName: String = #function
    ) async {
        let colorSchemes: [ColorScheme] = [.light, .dark]
        let dynamicTypeSizes: [DynamicTypeSize] = [.xSmall, .medium, .xxLarge]
        for colorScheme in colorSchemes {
            for dynamicTypeSize in dynamicTypeSizes {
                let snapshottingView = view
                    .dynamicTypeSize(dynamicTypeSize)
                    .preferredColorScheme(colorScheme)
                    .framedToTestDeviceSize()
                    .environment(makePasteboard())
                    .environment(DeviceAuthenticationService(policy: deviceAuthenticationPolicy))
                let named = "\(colorScheme)_\(dynamicTypeSize)"

                assertSnapshot(
                    of: snapshottingView,
                    as: .image,
                    named: named,
                    testName: testName
                )
            }
        }
    }

    @MainActor
    private func makePasteboard() -> Pasteboard {
        Pasteboard(SystemPasteboardMock(), localSettings: LocalSettings(defaults: .init(userDefaults: .standard)))
    }
}
