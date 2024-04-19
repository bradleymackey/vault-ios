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

    func test_layout_titleOnly() {
        let sut = makeSUT(title: "Title", description: nil)

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_titleAndDescription() {
        let sut = makeSUT(title: "Title", description: "Short description")

        assertSnapshot(matching: sut, as: .image)
    }

    func test_layout_titleAndDescriptionTruncation() {
        let description = Array(repeating: "Testing", count: 50).joined(separator: " ")
        let sut = makeSUT(title: "Title", description: description)

        assertSnapshot(matching: sut, as: .image)
    }
}

// MARK: - Helpers

extension SecureNotePreviewViewSnapshotTests {
    private func makeSUT(
        title: String = "Title",
        description: String? = "Short Description"
    ) -> some View {
        let viewModel = SecureNotePreviewViewModel(title: title, description: description)
        return SecureNotePreviewView(viewModel: viewModel)
            .frame(width: 250)
    }
}
