import Foundation
import SwiftUI
import TestHelpers
import VaultFeed
import XCTest
@testable import VaultiOS

final class SecureNoteDetailViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    @MainActor
    func test_emptyState() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "", contents: ""),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "", contents: ""),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "", contents: ""),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "My Title", contents: ""),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "My Title", contents: "My contents"),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "My Title", contents: longContent),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "My Title", contents: "My contents"),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "", contents: ""),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
            editingExistingNote: .init(title: "My Title", contents: "My contents"),
            navigationPath: .constant(NavigationPath()),
            dataModel: VaultDataModel(vaultStore: VaultStoreStub(), vaultTagStore: VaultStoreStub()),
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
