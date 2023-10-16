import Foundation

public enum OTPCodeTimerAnimationState: Equatable {
    case freeze(fraction: Double)
    case animate(OTPCodeTimerState)
}

public extension OTPCodeTimerAnimationState {
    func initialFraction(currentTime: Double) -> Double {
        switch self {
        case let .freeze(fraction):
            return fraction
        case let .animate(state):
            return 1 - state.fractionCompleted(at: currentTime)
        }
    }

    static func countdownFrom(timerState: OTPCodeTimerState?) -> OTPCodeTimerAnimationState {
        guard let timerState else { return .freeze(fraction: 0) }
        return .animate(timerState)
    }
}
