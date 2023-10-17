import Foundation
import XCTest

extension XCTestCase {
    public func expectSingleMutation<T: Observable>(
        observable object: T,
        keyPath: KeyPath<T, some Any>,
        when action: () async throws -> Void
    ) async rethrows {
        let exp = expectation(description: "Wait for expectation")
        withObservationTracking {
            _ = object[keyPath: keyPath]
        } onChange: {
            // onChange is only called once per `withObservationTracking`
            exp.fulfill()
        }

        try await action()

        await fulfillment(of: [exp], timeout: 1.0)
    }

    public func expectNoMutation<T: Observable>(
        observable object: T,
        keyPath: KeyPath<T, some Any>,
        timeout: Double = 1.0,
        when action: () async throws -> Void
    ) async rethrows {
        let exp = expectation(description: "Wait for expectation")
        exp.isInverted = true
        withObservationTracking {
            _ = object[keyPath: keyPath]
        } onChange: {
            exp.fulfill()
        }

        try await action()

        await fulfillment(of: [exp], timeout: timeout)
    }
}
