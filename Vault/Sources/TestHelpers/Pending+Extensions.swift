import Foundation
import FoundationExtensions

public typealias TaskCancellationWaiter = Pending<Void>

extension Pending where Value == Void {
    public func waitForTaskCancellation() async {
        do {
            // Awaiting a value will throw `CancellationError` when the Task it's part of is cancelled.
            try await wait()
        } catch is CancellationError {
            // noop: expected
        } catch {
            preconditionFailure("Expected a cancellation error!")
        }
    }
}
