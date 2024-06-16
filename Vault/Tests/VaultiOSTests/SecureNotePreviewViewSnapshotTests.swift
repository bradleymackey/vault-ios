import Foundation
import SnapshotTesting
import SwiftUI
import VaultFeed
import XCTest
@testable import VaultiOS

final class SecureNotePreviewViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    @MainActor
    func test_layout_titleOnly() {
        let sut = makeSUT(title: "Title", description: nil)

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_titleOnlyLong() {
        let sut = makeSUT(title: "Title that is a little bit long, but's that's OK", description: nil)

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_titleAndDescription() {
        let sut = makeSUT(title: "Title", description: "Short description")

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_titleAndDescriptionTruncation() {
        let description = Array(repeating: "Testing description", count: 50).joined(separator: " ")
        let sut = makeSUT(title: "Title", description: description)

        assertSnapshot(matching: sut, as: .image)
    }

    @MainActor
    func test_layout_titleAndDescriptionTruncatesTitleFirst() {
        let title = Array(repeating: "Title", count: 50).joined(separator: " ")
        let description = Array(repeating: "Description", count: 50).joined(separator: " ")
        let sut = makeSUT(title: title, description: description)

        assertSnapshot(matching: sut, as: .image)
    }
}

// MARK: - Helpers

extension SecureNotePreviewViewSnapshotTests {
    @MainActor
    private func makeSUT(
        title: String = "Title",
        description: String? = "Short Description"
    ) -> some View {
        let viewModel = SecureNotePreviewViewModel(title: title, description: description, color: .default)
        return SecureNotePreviewView(viewModel: viewModel, behaviour: .normal)
            .frame(width: 250)
    }
}
