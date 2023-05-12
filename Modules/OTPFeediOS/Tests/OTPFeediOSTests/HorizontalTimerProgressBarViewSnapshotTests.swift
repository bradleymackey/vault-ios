import Combine
import SnapshotTesting
import XCTest
@testable import OTPFeediOS

final class HorizontalTimerProgressBarViewSnapshotTests: XCTestCase {
    func test_layout_empty() {
        let view = HorizontalTimerProgressBarView(
            fractionCompleted: 0,
            color: .blue
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_layout_halfFull() {
        let view = HorizontalTimerProgressBarView(
            fractionCompleted: 0.5,
            color: .blue
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_layout_full() {
        let view = HorizontalTimerProgressBarView(
            fractionCompleted: 1,
            color: .blue
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_layout_setsBackgroundColor() {
        let view = HorizontalTimerProgressBarView(
            fractionCompleted: 0.5,
            color: .blue,
            backgroundColor: .red
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_redactedPlaceholder_showsEmptyProgressBar() {
        let view = HorizontalTimerProgressBarView(
            fractionCompleted: 0.5,
            color: .blue,
            backgroundColor: .gray
        )
        .redacted(reason: .placeholder)
        .frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_redactedPrivacy_showsProgressStill() {
        let view = HorizontalTimerProgressBarView(fractionCompleted: 0.5, color: .blue)
            .redacted(reason: .privacy)
            .frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }
}
