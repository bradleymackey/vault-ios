import Combine
import Foundation
import OTPCore

public protocol CodeTimerUpdater {
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never>
}

/// Controller for producing timers for a given code, according to a clock.
public final class CodeTimerController<Timer: IntervalTimer>: CodeTimerUpdater {
    private let timerStateSubject: CurrentValueSubject<OTPTimerState, Never>
    private let period: Double
    private var timerPublisher: AnyCancellable?
    private let timer: Timer
    private let clock: EpochClock

    public init(timer: Timer, period: Double, clock: EpochClock) {
        self.period = period
        self.timer = timer
        self.clock = clock
        let initialState = Self.timerState(currentTime: clock.currentTime, period: period)
        timerStateSubject = .init(initialState)

        scheduleNextClock()
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    public func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        timerStateSubject.eraseToAnyPublisher()
    }
}

extension CodeTimerController {
    private func updateTimerState() {
        let nextState = Self.timerState(currentTime: clock.currentTime, period: period)
        timerStateSubject.send(nextState)
    }

    private func scheduleNextClock() {
        let remaining = timerStateSubject.value.remainingTime(at: clock.currentTime)
        timerPublisher = timer.wait(for: remaining)
            .sink { [weak self] in
                self?.updateTimerState()
                self?.scheduleNextClock()
            }
    }

    private static func timerState(currentTime: Double, period: Double) -> OTPTimerState {
        let currentCodeNumber = UInt64(currentTime) / UInt64(period)
        let nextCodeNumber = currentCodeNumber + 1
        let codeStart = currentCodeNumber * UInt64(period)
        let codeEnd = nextCodeNumber * UInt64(period)
        return OTPTimerState(startTime: Double(codeStart), endTime: Double(codeEnd))
    }
}
