import Foundation

public enum OTPCodeTimerAnimationState: Equatable {
    case freeze(fraction: Double)
    case animate(OTPCodeTimerState)
}

extension OTPCodeTimerAnimationState {
    public func initialFraction(currentTime: Double) -> Double {
        switch self {
        case let .freeze(fraction):
            fraction
        case let .animate(state):
            1 - state.fractionCompleted(at: currentTime)
        }
    }

    public static func countdownFrom(timerState: OTPCodeTimerState?) -> OTPCodeTimerAnimationState {
        guard let timerState else { return .freeze(fraction: 0) }
        return .animate(timerState)
    }
}
