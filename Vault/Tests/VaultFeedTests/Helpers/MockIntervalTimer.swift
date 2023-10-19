import Combine
import Foundation
import VaultCore

final class MockIntervalTimer: IntervalTimer {
    private let timerPublisher = PassthroughSubject<Void, Never>()

    func finishTimer() {
        timerPublisher.send()
    }

    func wait(for _: Double) -> AnyPublisher<Void, Never> {
        timerPublisher.first().eraseToAnyPublisher()
    }
}
