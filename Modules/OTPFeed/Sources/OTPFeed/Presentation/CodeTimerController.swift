import Combine
import Foundation
import OTPCore

public protocol CodeTimerUpdater {
    func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never>
}

/// Controller for producing timers for a given code, according to a clock.
public final class CodeTimerController<IntervalTimer: IntervalClock>: CodeTimerUpdater {
    private let timerStateSubject: CurrentValueSubject<OTPTimerState, Never>
    private let period: Double
    private var timerPublisher: AnyCancellable?
    private let intervalTimer: IntervalTimer
    private let currentTime: () -> Double

    public init(intervalTimer: IntervalTimer, period: Double, currentTime: @escaping () -> Double) {
        self.period = period
        self.intervalTimer = intervalTimer
        self.currentTime = currentTime
        let initialState = Self.timerState(currentTime: currentTime(), period: period)
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
        let nextState = Self.timerState(currentTime: currentTime(), period: period)
        timerStateSubject.send(nextState)
    }

    private func scheduleNextClock() {
        let remaining = timerStateSubject.value.remainingTime(at: currentTime())
        timerPublisher = intervalTimer.timerPublisher(time: remaining)
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
