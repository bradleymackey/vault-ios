import Combine
import Foundation
import OTPCore

struct MockEpochClock: EpochClock, IntervalClock {
    private let publisher: CurrentValueSubject<Double, Never>
    init(initialTime: Double) {
        publisher = CurrentValueSubject<Double, Never>(initialTime)
    }

    func tick() {
        publisher.send(publisher.value)
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

    private let timerPublisher = PassthroughSubject<Double, Never>()

    func finishTimer(currentTime: Double) {
        timerPublisher.send(currentTime)
    }

    func timerPublisher(interval _: Double) -> AnyPublisher<Double, Never> {
        timerPublisher.eraseToAnyPublisher()
    }
}
