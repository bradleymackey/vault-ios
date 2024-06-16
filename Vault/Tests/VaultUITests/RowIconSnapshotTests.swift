import SnapshotTesting
import SwiftUI
import XCTest
@testable import VaultUI

final class RowIconSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    func test_layout_smallFontSize() {
        let view = RowIcon(icon: Image(systemName: "book"), color: .blue)
            .font(.footnote)

        assertSnapshot(matching: view, as: .image)
    }

    func test_layout_mediumFontSize() {
        let view = RowIcon(icon: Image(systemName: "book"), color: .blue, size: 100)
            .font(.headline)

        assertSnapshot(matching: view, as: .image)
    }

    func test_color_foregroundColor() {
        let view = RowIcon(icon: Image(systemName: "eraser"), color: .blue)
            .font(.headline)
            .foregroundColor(.white)

        assertSnapshot(matching: view, as: .image)
    }
}
