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
        epoch - endTime
    }
}
