import Foundation

public enum CodeTimerAnimationState: Equatable {
    case freeze(fraction: Double)
    case animate(startFraction: Double, duration: Double)
}

public extension CodeTimerAnimationState {
    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .animate(fraction, _):
            return fraction
        }
    }

    static func countdownFrom(timerState: OTPTimerState?, currentTime: Double) -> CodeTimerAnimationState {
        guard let timerState else { return .freeze(fraction: 0) }
        let completed = timerState.fractionCompleted(at: currentTime)
        let remainingTime = timerState.remainingTime(at: currentTime)
        return .animate(startFraction: 1 - completed, duration: remainingTime)
    }
}
