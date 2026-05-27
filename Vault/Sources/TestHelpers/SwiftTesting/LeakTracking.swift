import Foundation
import FoundationExtensions
import Testing

/// Tracks weak references to objects that should deallocate by the end of a test scope.
///
/// You normally do not interact with `LeakTracker` directly — apply ``Testing/Trait/trackLeaks``
/// to a `@Test` or `@Suite`, then register objects via ``trackForMemoryLeaks(_:sourceLocation:)``.
public final class LeakTracker: Sendable {
    @TaskLocal
    public static var current: LeakTracker?

    // `WeakBox<AnyObject>` is not `Sendable` because `AnyObject` has no `Sendable` constraint, but
    // all reads/writes of `Entry` go through the `SharedMutex` below, which serialises access. The
    // `weak` storage itself is implemented atomically by the runtime.
    // swiftlint:disable:next no_unchecked_sendable
    private struct Entry: @unchecked Sendable {
        let ref: WeakBox<AnyObject>
        let typeName: String
        let sourceLocation: SourceLocation
    }

    private let entries = SharedMutex<[Entry]>([])

    init() {}

    fileprivate func track(_ instance: AnyObject, typeName: String, sourceLocation: SourceLocation) {
        let entry = Entry(ref: WeakBox(instance), typeName: typeName, sourceLocation: sourceLocation)
        entries.modify { $0.append(entry) }
    }

    func verify() {
        let snapshot = entries.modify { current -> [Entry] in
            let copy = current
            current.removeAll()
            return copy
        }
        for entry in snapshot where entry.ref.value != nil {
            Issue.record(
                "Potential memory leak: \(entry.typeName) was not deallocated at end of test scope.",
                sourceLocation: entry.sourceLocation,
            )
        }
    }
}

/// Scopes a ``LeakTracker`` to each `@Test` in the trait's scope. Use via ``Testing/Trait/trackLeaks``.
///
/// `SuiteTrait.isRecursive` defaults to `false`, so applying `.trackLeaks` to an outer `@Suite`
/// does not bleed into nested suites — those must opt in independently.
public struct TrackLeaks: TestTrait, SuiteTrait, TestScoping {
    public func provideScope(
        for _: Test,
        testCase _: Test.Case?,
        performing function: @Sendable () async throws -> Void,
    ) async throws {
        let tracker = LeakTracker()
        try await LeakTracker.$current.withValue(tracker) {
            try await function()
        }
        tracker.verify()
    }
}

extension Trait where Self == TrackLeaks {
    /// Records an Issue for any object registered via ``trackForMemoryLeaks(_:sourceLocation:)``
    /// that is still alive when the test scope ends.
    public static var trackLeaks: Self { TrackLeaks() }
}

/// Registers `instance` with the currently active ``LeakTracker``. When the enclosing test scope
/// ends, an Issue is recorded if `instance` has not been deallocated.
///
/// Must be called inside a `@Test` or `@Suite` carrying the ``Testing/Trait/trackLeaks`` trait.
/// Calls outside such a scope record an Issue at `sourceLocation` so misuse is loud.
///
/// Returns its argument so it can be chained at the construction site:
/// ```swift
/// let sut = trackForMemoryLeaks(VaultStore(...))
/// ```
@discardableResult
public func trackForMemoryLeaks<T: AnyObject>(
    _ instance: @autoclosure () -> T,
    sourceLocation: SourceLocation = #_sourceLocation,
) -> T {
    let value = instance()
    guard let tracker = LeakTracker.current else {
        Issue.record(
            "trackForMemoryLeaks called without an active .trackLeaks trait. Add `.trackLeaks` to the @Test or @Suite.",
            sourceLocation: sourceLocation,
        )
        return value
    }
    tracker.track(value, typeName: String(describing: T.self), sourceLocation: sourceLocation)
    return value
}
