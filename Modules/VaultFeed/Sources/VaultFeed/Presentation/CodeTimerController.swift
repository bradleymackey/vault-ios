import Combine
import Foundation
import VaultCore

public protocol CodeTimerUpdater {
    func recalculate()
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never>
}

/// Controller for producing timers for a given code, according to a clock.
public final class CodeTimerController: CodeTimerUpdater {
    private let timerStateSubject: CurrentValueSubject<OTPTimerState, Never>
    private let period: UInt64
    private var timerPublisher: AnyCancellable?
    private let timer: any IntervalTimer
    private let clock: EpochClock

    public init(timer: any IntervalTimer, period: UInt64, clock: EpochClock) {
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

    /// Forces the timer to recalculate it's current state and republish.
    public func recalculate() {
        let nextState = Self.timerState(currentTime: clock.currentTime, period: period)
        timerStateSubject.send(nextState)
    }
}

extension CodeTimerController {
    private func scheduleNextClock() {
        let remaining = timerStateSubject.value.remainingTime(at: clock.currentTime)
        timerPublisher = timer.wait(for: remaining)
            .sink { [weak self] in
                self?.recalculate()
                self?.scheduleNextClock()
            }
    }

    private static func timerState(currentTime: Double, period: UInt64) -> OTPTimerState {
        let currentCodeNumber = UInt64(currentTime) / period
        let nextCodeNumber = currentCodeNumber + 1
        let codeStart = currentCodeNumber * period
        let codeEnd = nextCodeNumber * period
        return OTPTimerState(startTime: Double(codeStart), endTime: Double(codeEnd))
    }
}
