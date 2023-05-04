import Combine
import Foundation

/// Epoch clock that derives the time from the injected time.
public struct CurrentDateEpochClock: EpochClock {
    private var currentDate: () -> Date

    public init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }

    public func secondsPublisher() -> AnyPublisher<UInt64, Never> {
        Timer.publish(every: 0.5, on: .main, in: .default)
            .autoconnect()
            .removeDuplicates()
            .map { _ in
                UInt64(currentDate().timeIntervalSince1970)
            }
            .eraseToAnyPublisher()
    }

    public var currentTime: UInt64 {
        UInt64(currentDate().timeIntervalSince1970)
    }
}
