import Foundation

public struct OTPCodeTimerState: Equatable {
    /// The number of epoch seconds when the timer started.
    public var startTime: Double
    /// The number of epoch seconds when the timer will end.
    public var endTime: Double

    public init(startTime: Double, endTime: Double) {
        self.startTime = startTime
        self.endTime = endTime
    }
}

public extension OTPCodeTimerState {
    /// The duration for a full timer rotation.
    var totalTime: Double {
        endTime - startTime
    }

    /// The amount of time remaining before the timer runs out.
    ///
    /// This won't go below 0.
    func remainingTime(at epoch: Double) -> Double {
        max(0, endTime - epoch)
    }

    /// The fraction of the timer that has already been completed at the given time.
    ///
    /// This will only give an output `0...1`.
    func fractionCompleted(at epoch: Double) -> Double {
        if totalTime == 0 { return 1 }
        let remainingTime = remainingTime(at: epoch)
        let remainingFraction = remainingTime / totalTime
        let fractionCompleted = 1 - remainingFraction
        return fractionCompleted.clamped(to: 0 ... 1)
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
