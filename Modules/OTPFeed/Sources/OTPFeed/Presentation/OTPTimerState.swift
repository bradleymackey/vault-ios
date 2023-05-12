import Foundation

public struct OTPTimerState: Equatable {
    /// The number of epoch seconds when the timer started.
    public var startTime: Double
    /// The number of epoch seconds when the timer will end.
    public var endTime: Double

    /// The duration for a full timer rotation.
    public var totalTime: Double {
        endTime - startTime
    }

    public init(startTime: Double, endTime: Double) {
        self.startTime = startTime
        self.endTime = endTime
    }

    public func remainingTime(at epoch: Double) -> Double {
        max(0, endTime - epoch)
    }

    public func fractionCompleted(at epoch: Double) -> Double {
        if totalTime == 0 { return 1 }
        let remainingTime = remainingTime(at: epoch)
        let remainingFraction = remainingTime / totalTime
        let fractionCompleted = 1 - remainingFraction
        if fractionCompleted > 1 {
            return 1
        } else if fractionCompleted < 0 {
            return 0
        } else {
            return fractionCompleted
        }
    }
}
