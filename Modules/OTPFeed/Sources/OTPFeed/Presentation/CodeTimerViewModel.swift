import Combine
import Foundation
import OTPCore

public final class CodeTimerViewModel: ObservableObject {
    private let timerStateSubject: CurrentValueSubject<OTPTimerState, Never>
    private let period: Double

    public init(clock: some EpochClock, period: UInt32) {
        self.period = Double(period)
        let currentCodeNumber = UInt64(clock.currentTime) / UInt64(period)
        let nextCodeNumber = currentCodeNumber + 1
        let codeStart = currentCodeNumber * UInt64(period)
        let codeEnd = nextCodeNumber * UInt64(period)
        let initialState = OTPTimerState(startTime: Double(codeStart), endTime: Double(codeEnd))
        timerStateSubject = .init(initialState)
    }

    /// Publishes when there is a change to the timer that needs to be reflected in the view.
    public func timerUpdatedPublisher() -> AnyPublisher<OTPTimerState, Never> {
        timerStateSubject.eraseToAnyPublisher()
    }
}
