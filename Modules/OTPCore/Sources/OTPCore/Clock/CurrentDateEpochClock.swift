import Combine
import Foundation

/// Epoch clock that derives the time from the injected time.
public struct CurrentDateEpochClock: EpochClock {
    private var currentDate: () -> Date
    private let clockSubject = PassthroughSubject<Date, Never>()

    public init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }

    public func tick() {
        clockSubject.send(currentDate())
    }

    public func secondsPublisher() -> AnyPublisher<Double, Never> {
        clockSubject.map { date in
            date.timeIntervalSince1970
        }
        .eraseToAnyPublisher()
    }

    public var currentTime: Double {
        currentDate().timeIntervalSince1970
    }
}

extension CurrentDateEpochClock: IntervalClock {
    public func timerPublisher(interval: Double) -> AnyPublisher<Void, Never> {
        Timer.TimerPublisher(interval: interval, runLoop: .main, mode: .default)
            .autoconnect()
            .map { _ in }
            .first()
            .eraseToAnyPublisher()
    }
}
