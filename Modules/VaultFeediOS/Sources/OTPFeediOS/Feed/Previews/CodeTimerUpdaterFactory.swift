import Foundation
import VaultCore
import VaultFeed

public protocol CodeTimerUpdaterFactory {
    func makeUpdater(period: UInt64) -> any CodeTimerUpdater
}

public final class CodeTimerControllerFactory: CodeTimerUpdaterFactory {
    let timer: any IntervalTimer
    let clock: EpochClock

    public init(timer: any IntervalTimer, clock: EpochClock) {
        self.timer = timer
        self.clock = clock
    }

    public func makeUpdater(period: UInt64) -> any CodeTimerUpdater {
        CodeTimerController(timer: timer, period: period, clock: clock)
    }
}
