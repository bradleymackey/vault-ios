import Foundation
import OTPFeed

enum CodeTimerAnimationState: Equatable {
    case freeze(fraction: Double)
    case animate(startFraction: Double, duration: Double)

    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .animate(fraction, _):
            return fraction
        }
    }
}

extension CodeTimerAnimationState {
    init(timerState _: OTPTimerState?) {
        self = .freeze(fraction: 0)
    }
}
