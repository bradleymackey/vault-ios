import Foundation
import VaultCore
import VaultFeed

public protocol OTPCodeTimerUpdaterFactory {
    func makeUpdater(period: UInt64) -> any OTPCodeTimerUpdater
}

public final class OTPCodeTimerUpdaterFactoryImpl: OTPCodeTimerUpdaterFactory {
    let timer: any IntervalTimer
    let clock: EpochClock

    public init(timer: any IntervalTimer, clock: EpochClock) {
        self.timer = timer
        self.clock = clock
    }

    public func makeUpdater(period: UInt64) -> any OTPCodeTimerUpdater {
        OTPCodeTimerUpdaterImpl(timer: timer, period: period, clock: clock)
    }
}
