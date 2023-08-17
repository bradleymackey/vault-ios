import Combine
import SnapshotTesting
import XCTest
@testable import OTPFeediOS

final class CodeIconPlaceholderViewSnapshotTests: XCTestCase {
    func test_layout_smallSize() {
        let view = CodeIconPlaceholderView(iconFontSize: 22)

        assertSnapshot(matching: view, as: .image)
    }

    func test_layout_mediumSize() {
        let view = CodeIconPlaceholderView(iconFontSize: 44)

        assertSnapshot(matching: view, as: .image)
    }
}
