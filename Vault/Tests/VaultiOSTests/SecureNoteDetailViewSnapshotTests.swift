import Foundation
import SwiftUI
import TestHelpers
import VaultFeed
import XCTest
@testable import VaultiOS

final class SecureNoteDetailViewSnapshotTests: XCTestCase {
    @MainActor
    func test_emptyState() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "", contents: "", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: "",
                lockState: .notLocked,
                color: nil
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_lockedState() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "", contents: "", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .lockedWithNativeSecurity,
                color: nil
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_lockedStateNoAuthentication() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "", contents: "", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .lockedWithNativeSecurity,
                color: nil
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut, deviceAuthenticationPolicy: .cannotAuthenticate)
    }

    @MainActor
    func test_titleOnly() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: "", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .none,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .notLocked,
                color: nil
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_titleDescriptionAndShortContent() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: "My contents", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "My description",
                tags: [],
                visibility: .always,
                searchableLevel: .onlyTitle,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .notLocked,
                color: nil
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_titleDescriptionAndLongContent() async {
        let longContent = Array(repeating: "My content is cool.", count: 100).joined(separator: " ")
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: longContent, format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "My description",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .notLocked,
                color: .gray
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_contentUpdated() async {
        let date = fixedTestDate()
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: "My contents", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: date,
                updated: date.addingTimeInterval(1), // different updated date
                relativeOrder: .min,
                userDescription: "My description",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .notLocked,
                color: .black
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_editMode_emptyState() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "", contents: "", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .notLocked,
                color: nil
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: true
        )

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_editMode_editedContent() async {
        let date = fixedTestDate()
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: "My contents", format: .markdown),
            encryptionKey: nil,
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: date,
                updated: date.addingTimeInterval(1), // different updated date
                relativeOrder: .min,
                userDescription: "My description",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: "",
                killphrase: nil,
                lockState: .notLocked,
                color: .black
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: true
        )

        await snapshotScenarios(view: sut)
    }
}

// MARK: - Helpers

extension SecureNoteDetailViewSnapshotTests {
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

    private func fixedTestDate() -> Date {
        Date(timeIntervalSince1970: 40000)
    }
}
