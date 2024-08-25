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

        scheduleNextUpdate()
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    public func timerUpdatedPublisher() -> AnyPublisher<OTPCodeTimerState, Never> {
        timerStateSubject
            .eraseToAnyPublisher()
    }

    /// Forces the timer to recalculate it's current state and republish.
    public func recalculate() {
        timerPublisher?.cancel()
        let currentState = OTPCodeTimerState(currentTime: clock.currentTime, period: period)
        timerStateSubject.send(currentState)
        scheduleNextUpdate()
    }
}

extension OTPCodeTimerUpdaterImpl {
    /// Schedules the next display of the timer state.
    private func scheduleNextUpdate() {
        timerPublisher?.cancel()
        let currentState = timerStateSubject.value
        let targetState = currentState.offset(time: Double(period))
        // Add some additional tolerance
        let timeUntilTarget = targetState.startTime - clock.currentTime + 0.1
        // Wait with some additional tolerance (it's OK if we're a little late)
        // This can help system performance
        timerPublisher = timer.wait(for: timeUntilTarget, tolerance: timeUntilTarget / 10)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] in
                self?.timerStateSubject.send(targetState)
                self?.scheduleNextUpdate()
            }
    }
}
