import Foundation
import VaultCore

/// @mockable
public protocol OTPCodeTimerUpdaterFactory {
    @MainActor func makeUpdater(period: UInt64) -> any OTPCodeTimerUpdater
}

public final class OTPCodeTimerUpdaterFactoryImpl: OTPCodeTimerUpdaterFactory {
    let timer: any IntervalTimer
    let clock: any EpochClock

    public init(timer: any IntervalTimer, clock: any EpochClock) {
        self.timer = timer
        self.clock = clock
    }

    @MainActor
    public func makeUpdater(period: UInt64) -> any OTPCodeTimerUpdater {
        OTPCodeTimerUpdaterImpl(timer: timer, period: period, clock: clock)
    }
}
