import Foundation

public struct OTPTimerState: Equatable {
    /// The duration for a full timer rotation.
    public var totalTime: Double
    /// The amount of time elapsed in the current total time.
    /// This will be less than or equal to `totalTime`.
    public var timeElapsed: Double

    /// The fraction of the time remaining.
    public var fractionCompleted: Double {
        if totalTime == 0 { return 0 }
        return timeElapsed / totalTime
    }
}
