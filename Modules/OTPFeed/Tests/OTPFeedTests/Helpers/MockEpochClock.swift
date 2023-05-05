import Combine
import Foundation
import OTPCore

final class MockEpochClock: EpochClock, IntervalClock {
    private let publisher: CurrentValueSubject<Double, Never>
    init(initialTime: Double) {
        publisher = CurrentValueSubject<Double, Never>(initialTime)
    }

    var didTick: () -> Void = {}

    func tick() {
        publisher.send(publisher.value)
        didTick()
    }

    func send(time: Double) {
        publisher.send(time)
    }

    func secondsPublisher() -> AnyPublisher<Double, Never> {
        publisher.eraseToAnyPublisher()
    }

    var currentTime: Double {
        publisher.value
    }

    private let timerPublisher = PassthroughSubject<Void, Never>()

    func finishTimer() {
        timerPublisher.send()
    }

    func timerPublisher(time _: Double) -> AnyPublisher<Void, Never> {
        timerPublisher.first().eraseToAnyPublisher()
    }
}
