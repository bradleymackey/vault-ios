import Combine
import Foundation
import OTPCore

public final class CodeTimerViewModel: ObservableObject {
    private let timerStateSubject = PassthroughSubject<OTPTimerState, Never>()
    private let secondsPublisher: AnyPublisher<Double, Never>
    private let period: Double

    public init(clock: some EpochClock, period: UInt32) {
        self.period = Double(period)
        secondsPublisher = clock.secondsPublisher()
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    public func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        secondsPublisher.map { epochSeconds in
            self.computeState(currentSeconds: epochSeconds)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    /// Computes the state of the timer
    private func computeState(currentSeconds: Double) -> OTPTimerState {
        let elapsedSecondsInPeriod = currentSeconds.truncatingRemainder(dividingBy: period)
        return OTPTimerState(totalTime: period, timeElapsed: elapsedSecondsInPeriod)
    }
}
