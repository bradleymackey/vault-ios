import Foundation
import SnapshotTesting
import SwiftUI
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
struct EncryptedItemPreviewViewSnapshotTests {
    @Test
    func layout_color() {
        let sut = makeSUT(title: "Hello", color: VaultItemColor(red: 0.3, green: 0.1, blue: 0.8))

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_emptyTitle() {
        let sut = makeSUT(title: "")

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_shortTitle() {
        let sut = makeSUT(title: "Hello")

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_mediumTitle() {
        let sut = makeSUT(title: "Hello there this is a pretty long title, but not too long.")

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_longTitle() {
        let title = Array(repeating: "That is so cool.", count: 50).joined(separator: " ")
        let sut = makeSUT(title: title)

        assertSnapshot(of: sut, as: .image)
    }
}

// MARK: - Helpers

extension EncryptedItemPreviewViewSnapshotTests {
    private func makeSUT(
        title: String = "",
        color: VaultItemColor = .default,
    ) -> some View {
        let viewModel = EncryptedItemPreviewViewModel(title: title, color: color)
        return EncryptedItemPreviewView(viewModel: viewModel, behaviour: .normal)
            .frame(width: 250)
    }
}
