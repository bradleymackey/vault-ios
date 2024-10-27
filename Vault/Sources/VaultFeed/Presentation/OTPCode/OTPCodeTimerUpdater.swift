import Combine
import Foundation
import VaultCore

/// @mockable
@MainActor
public protocol OTPCodeTimerUpdater {
    /// Updates the timer immediately and schedules regular updates..
    func recalculate()
    /// Cancels the timer and stops updates.
    func cancel()
    var timerUpdatedPublisher: AnyPublisher<OTPCodeTimerState, Never> { get }
}

/// Controller for producing timers for a given code, according to a clock.
@MainActor
public final class OTPCodeTimerUpdaterImpl: OTPCodeTimerUpdater, Sendable {
    private let timerStateSubject: CurrentValueSubject<OTPCodeTimerState, Never>
    private let timerFiredSubject = PassthroughSubject<Void, Never>()
    private let period: UInt64
    private let timerTask = SharedMutex<Task<Void, any Error>?>(nil)
    private let timer: any IntervalTimer
    private let clock: any EpochClock

    public init(timer: any IntervalTimer, period: UInt64, clock: any EpochClock) {
        self.period = period
        self.timer = timer
        self.clock = clock
        let initialState = OTPCodeTimerState(currentTime: clock.currentTime, period: period)
        timerStateSubject = .init(initialState)

        scheduleNextUpdate()
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    public var timerUpdatedPublisher: AnyPublisher<OTPCodeTimerState, Never> {
        timerStateSubject
            .eraseToAnyPublisher()
    }

    public var timerFiredPublisher: AnyPublisher<Void, Never> {
        timerFiredSubject.eraseToAnyPublisher()
    }

    /// Forces the timer to recalculate it's current state and republish.
    public func recalculate() {
        timerTask.value?.cancel()
        let currentState = OTPCodeTimerState(currentTime: clock.currentTime, period: period)
        timerStateSubject.send(currentState)
        scheduleNextUpdate()
    }

    public func cancel() {
        timerTask.modify {
            $0?.cancel()
            $0 = nil
        }
    }
}

extension OTPCodeTimerUpdaterImpl {
    /// Schedules the next display of the timer state.
    private func scheduleNextUpdate() {
        timerTask.value?.cancel()
        let currentState = timerStateSubject.value
        let targetState = currentState.offset(time: Double(period))
        // Add some additional tolerance
        let timeUntilTarget = targetState.startTime - clock.currentTime + 0.1
        // Wait with some additional tolerance (it's OK if we're a little late)
        // This can help system performance
        timerTask.modify {
            $0 = timer.schedule(wait: timeUntilTarget, tolerance: 0.2) { @MainActor [weak self] in
                self?.scheduleNextUpdate()
                self?.timerStateSubject.send(targetState)
                self?.timerFiredSubject.send()
            }
        }
    }
}
