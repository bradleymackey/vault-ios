import Combine
import SnapshotTesting
import XCTest
@testable import VaultiOS

final class CodeIconPlaceholderViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
//        isRecording = true
    }

    func test_layout_smallSize() {
        let view = OTPCodeIconPlaceholderView(iconFontSize: 22)

        assertSnapshot(of: view, as: .image)
    }

    func test_layout_mediumSize() {
        let view = OTPCodeIconPlaceholderView(iconFontSize: 44)

        assertSnapshot(of: view, as: .image)
    }
}
