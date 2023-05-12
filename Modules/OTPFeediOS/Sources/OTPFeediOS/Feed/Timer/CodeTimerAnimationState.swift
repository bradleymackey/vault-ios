import Foundation

enum CodeTimerAnimationState {
    case freeze(fraction: Double)
    case animate(startFraction: Double, duration: Double)

    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .animate(fraction, _):
            return fraction
        }
    }
}
