import Combine
import Foundation
import VaultCore

public protocol OTPCodeTimerUpdater {
    func recalculate()
    func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never>
}

// MARK: - Mock

public final class OTPCodeTimerUpdaterMock: OTPCodeTimerUpdater {
    public init() {}

    public let subject = PassthroughSubject<OTPCodeTimerState, Never>()
    public var recalculateCallCount = 0
    public func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        subject.eraseToAnyPublisher()
    }

    public func recalculate() {
        recalculateCallCount += 1
    }
}

// MARK: - Impl

/// Controller for producing timers for a given code, according to a clock.
public final class OTPCodeTimerUpdaterImpl: OTPCodeTimerUpdater {
    private let timerStateSubject: CurrentValueSubject<OTPCodeTimerState, Never>
    private let period: UInt64
    private var timerPublisher: AnyCancellable?
    private let timer: any IntervalTimer
    private let clock: any EpochClock

    public init(timer: any IntervalTimer, period: UInt64, clock: any EpochClock) {
        self.period = period
        self.timer = timer
        self.clock = clock
        let initialState = OTPCodeTimerState(currentTime: clock.currentTime, period: period)
        timerStateSubject = .init(initialState)

        scheduleNextClock()
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    public func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        timerStateSubject.eraseToAnyPublisher()
    }

    /// Forces the timer to recalculate it's current state and republish.
    public func recalculate() {
        let nextState = OTPCodeTimerState(currentTime: clock.currentTime, period: period)
        timerStateSubject.send(nextState)
    }
}

extension OTPCodeTimerUpdaterImpl {
    private func scheduleNextClock() {
        let remaining = timerStateSubject.value.remainingTime(at: clock.currentTime)
        timerPublisher?.cancel()
        timerPublisher = timer.wait(for: remaining)
            .sink { [weak self] in
                self?.recalculate()
                self?.scheduleNextClock()
            }
    }
}
