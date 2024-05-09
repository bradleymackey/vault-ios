import Foundation
import SwiftUI
import TestHelpers
import VaultFeed
import XCTest
@testable import VaultiOS

final class SecureNoteDetailViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    @MainActor
    func test_emptyState() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "", contents: ""),
            storedMetadata: .init(id: UUID(), created: fixedTestDate(), updated: fixedTestDate(), userDescription: ""),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )
        .framedToTestDeviceSize()

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_titleOnly() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: ""),
            storedMetadata: .init(id: UUID(), created: fixedTestDate(), updated: fixedTestDate(), userDescription: ""),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )
        .framedToTestDeviceSize()

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_titleDescriptionAndShortContent() async {
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: "My contents"),
            storedMetadata: .init(
                id: UUID(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                userDescription: "My description"
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )
        .framedToTestDeviceSize()

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_titleDescriptionAndLongContent() async {
        let longContent = Array(repeating: "My content is cool.", count: 100).joined(separator: " ")
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: longContent),
            storedMetadata: .init(
                id: UUID(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                userDescription: "My description"
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )
        .framedToTestDeviceSize()

        await snapshotScenarios(view: sut)
    }

    @MainActor
    func test_contentUpdated() async {
        let date = fixedTestDate()
        let sut = SecureNoteDetailView(
            editingExistingNote: .init(title: "My Title", contents: "My contents"),
            storedMetadata: .init(
                id: UUID(),
                created: date,
                updated: date.addingTimeInterval(1), // different updated date
                userDescription: "My description"
            ),
            editor: SecureNoteDetailEditorMock(),
            openInEditMode: false
        )
        .framedToTestDeviceSize()

        await snapshotScenarios(view: sut)
    }
}

// MARK: - Helpers

extension SecureNoteDetailViewSnapshotTests {
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

    private func fixedTestDate() -> Date {
        Date(timeIntervalSince1970: 40000)
    }
}
