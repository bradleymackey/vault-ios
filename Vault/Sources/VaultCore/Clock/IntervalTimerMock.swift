import Combine
import Foundation

public final class IntervalTimerMock: IntervalTimer {
    private let waitSubject = PassthroughSubject<Void, Never>()
    /// Mock: the intervals that were waited for.
    public var waitArgValues = [Double]()

    public init() {}

    public func finishTimer() {
        waitSubject.send()
    }

    public func wait(for time: Double) -> AnyPublisher<Void, Never> {
        waitArgValues.append(time)
        return waitSubject.first().eraseToAnyPublisher()
    }
}
