import Foundation
import SwiftUI
import TestHelpers
import VaultFeed
import VaultSettings
import XCTest
@testable import VaultiOS

final class OTPCodeDetailViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    @MainActor
    func test_emptyState() async {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            storedMetadata: .init(
                id: UUID(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                userDescription: "",
                tags: .init(ids: []),
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                color: nil
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock(),
            openInEditMode: false,
            presentationMode: .none
        )
        .framedToTestDeviceSize()
        .environment(makePasteboard())

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_withUserDescription() async {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            storedMetadata: .init(
                id: UUID(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                userDescription: "This is my description",
                tags: .init(ids: []),
                visibility: .onlySearch,
                searchableLevel: .onlyTitle,
                searchPassphrase: "",
                color: nil
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock(),
            openInEditMode: false,
            presentationMode: .none
        )
        .framedToTestDeviceSize()
        .environment(makePasteboard())

        await snapshotScenarios(view: sut)
    }
}

// MARK: - Helpers

extension OTPCodeDetailViewSnapshotTests {
    @MainActor
    private func snapshotScenarios(view: some View, testName: String = #function) async {
        let colorSchemes: [ColorScheme] = [.light, .dark]
        let dynamicTypeSizes: [DynamicTypeSize] = [.xSmall, .medium, .xxLarge]
        for colorScheme in colorSchemes {
            for dynamicTypeSize in dynamicTypeSizes {
                let snapshottingView = view
                    .dynamicTypeSize(dynamicTypeSize)
                    .preferredColorScheme(colorScheme)
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

    private func fixedTestDate() -> Date {
        Date(timeIntervalSince1970: 40000)
    }
}
