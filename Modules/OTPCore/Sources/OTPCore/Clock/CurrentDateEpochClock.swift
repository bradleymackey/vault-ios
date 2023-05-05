import Combine
import Foundation

/// Epoch clock that derives the time from the injected time.
public final class CurrentDateEpochClock: EpochClock, ObservableObject {
    private var currentDate: () -> Date
    private let clockSubject = PassthroughSubject<Date, Never>()

    public init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }

    public func tick() {
        objectWillChange.send()
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
    public func timerPublisher(time: Double) -> AnyPublisher<Void, Never> {
        Timer.TimerPublisher(interval: time, runLoop: .main, mode: .default)
            .autoconnect()
            .map { _ in }
            .first() // only publish once
            .eraseToAnyPublisher()
    }
}
