import Combine
import CombineTestExtensions

extension Publisher {
    /// Record data from `@Published`, which ignores the first published result (that we often don't care about).
    func recordPublished(numberOfRecords: Int) -> TimedRecorder<Output, Failure> {
        dropFirst().record(scheduler: TestScheduler(), numberOfRecords: numberOfRecords)
    }
}
