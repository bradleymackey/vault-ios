import Combine
import Foundation
import VaultCore

final class MockIntervalTimer: IntervalTimer {
    private let timerPublisher = PassthroughSubject<Void, Never>()
    /// Mock: the intervals that were waited for.
    var recordedWaitedIntervals = [Double]()

    func finishTimer() {
        timerPublisher.send()
    }

    func wait(for time: Double) -> AnyPublisher<Void, Never> {
        recordedWaitedIntervals.append(time)
        return timerPublisher.first().eraseToAnyPublisher()
    }
}
