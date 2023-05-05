import Combine
import SnapshotTesting
import XCTest
@testable import OTPFeediOS

final class HorizontalTimerProgressBarViewSnapshotTests: XCTestCase {
    func test_initialFraction_empty() {
        let view = HorizontalTimerProgressBarView(
            initialFractionCompleted: 0,
            startSignaller: PassthroughSubject().eraseToAnyPublisher(),
            color: .blue
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_initialFraction_halfFull() {
        let view = HorizontalTimerProgressBarView(
            initialFractionCompleted: 0.5,
            startSignaller: PassthroughSubject().eraseToAnyPublisher(),
            color: .blue
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }

    func test_initialFraction_full() {
        let view = HorizontalTimerProgressBarView(
            initialFractionCompleted: 1,
            startSignaller: PassthroughSubject().eraseToAnyPublisher(),
            color: .blue
        ).frame(width: 150, height: 20)

        assertSnapshot(matching: view, as: .image)
    }
}
