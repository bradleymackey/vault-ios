import Foundation

enum CodeTimerAnimationState {
    case freeze(fraction: Double)
    case startAnimating(startFraction: Double, duration: Double)

    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .startAnimating(fraction, _):
            return fraction
        }
    }
}
