import CryptoEngine
import Foundation
import OTPCore
import OTPFeed

struct TOTPCodeMapper {
    let clock: EpochClock
    let period: Double
    let generator: TOTPGenerator
    let interval: LiveIntervalTimer

    init(period: Double, generator: TOTPGenerator, clock: EpochClock, interval: LiveIntervalTimer) {
        self.period = period
        self.clock = clock
        self.generator = generator
        self.interval = interval
    }

    func create()
        -> (CodeTimerController<LiveIntervalTimer>, TOTPCodeRenderer<CodeTimerController<LiveIntervalTimer>>)
    {
        let timer = CodeTimerController(timer: interval, period: period, clock: clock)
        let renderer = TOTPCodeRenderer(timer: timer, totpGenerator: generator)
        return (timer, renderer)
    }
}
