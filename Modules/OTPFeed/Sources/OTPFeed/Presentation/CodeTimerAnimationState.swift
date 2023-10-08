import Foundation

public enum CodeTimerAnimationState: Equatable {
    case freeze(fraction: Double)
    case animate(OTPTimerState)
}

public extension CodeTimerAnimationState {
    func initialFraction(currentTime: Double) -> Double {
        switch self {
        case let .freeze(fraction):
            return fraction
        case let .animate(state):
            return 1 - state.fractionCompleted(at: currentTime)
        }
    }

    static func countdownFrom(timerState: OTPTimerState?) -> CodeTimerAnimationState {
        guard let timerState else { return .freeze(fraction: 0) }
        return .animate(timerState)
    }
}
