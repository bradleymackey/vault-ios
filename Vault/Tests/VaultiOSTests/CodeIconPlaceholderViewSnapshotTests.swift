import Combine
import SnapshotTesting
import Testing
@testable import VaultiOS

@Suite
@MainActor
final class CodeIconPlaceholderViewSnapshotTests {
    @Test
    func layout_smallSize() {
        let view = OTPCodeIconPlaceholderView(iconFontSize: 22)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func layout_mediumSize() {
        let view = OTPCodeIconPlaceholderView(iconFontSize: 44)

        assertSnapshot(of: view, as: .image)
    }
}
