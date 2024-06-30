import Combine
import Foundation

public final class IntervalTimerMock: IntervalTimer {
    private let timerPublisher = PassthroughSubject<Void, Never>()
    /// Mock: the intervals that were waited for.
    public var waitArgValues = [Double]()

    public init() {}

    public func finishTimer() {
        timerPublisher.send()
    }

    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        waitArgValues.append(time)
        return timerPublisher.first().eraseToAnyPublisher()
    }
}
