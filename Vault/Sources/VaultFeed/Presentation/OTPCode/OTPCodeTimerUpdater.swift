// `CurrentValueSubject` is not Sendable. This is worked around by ensuring that we only send values via this subject
// on the main thread.
// swiftlint:disable:next no_preconcurrency
@preconcurrency import Combine
import Foundation
import VaultCore

public protocol OTPCodeTimerUpdater {
    @MainActor func recalculate()
    @MainActor func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never>
}

// MARK: - Mock

public final class OTPCodeTimerUpdaterMock: OTPCodeTimerUpdater {
    public init() {}

    public let subject = PassthroughSubject<OTPCodeTimerState, Never>()
    public var recalculateCallCount = 0
    public func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        subject.eraseToAnyPublisher()
    }

    @MainActor
    public func recalculate() {
        recalculateCallCount += 1
    }
}

// MARK: - Impl

/// Controller for producing timers for a given code, according to a clock.
public final class OTPCodeTimerUpdaterImpl: OTPCodeTimerUpdater, Sendable {
    @MainActor
    private let timerStateSubject: CurrentValueSubject<OTPCodeTimerState, Never>
    private let period: UInt64
    private let timerTask = Atomic<Task<Void, any Error>?>(initialValue: nil)
    private let timer: any IntervalTimer
    private let clock: any EpochClock

    @MainActor
    public init(timer: any IntervalTimer, period: UInt64, clock: any EpochClock) {
        self.period = period
        self.timer = timer
        self.clock = clock
        let initialState = OTPCodeTimerState(currentTime: clock.currentTime, period: period)
        timerStateSubject = .init(initialState)

        scheduleNextUpdate()
    }

    deinit {
        cancel()
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    @MainActor
    public func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        timerStateSubject
            .eraseToAnyPublisher()
    }

    /// Forces the timer to recalculate it's current state and republish.
    @MainActor
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
    @MainActor
    private func scheduleNextUpdate() {
        timerTask.value?.cancel()
        let currentState = timerStateSubject.value
        let targetState = currentState.offset(time: Double(period))
        // Add some additional tolerance
        let timeUntilTarget = targetState.startTime - clock.currentTime + 0.1
        // Wait with some additional tolerance (it's OK if we're a little late)
        // This can help system performance
        timerTask.modify {
            $0 = timer.schedule(wait: timeUntilTarget, tolerance: 0.2) { [weak self] in
                DispatchQueue.main.async {
                    self?.scheduleNextUpdate()
                    self?.timerStateSubject.send(targetState)
                }
            }
        }
    }
}
