import Foundation
import XCTest

public extension XCTestCase {
    func expectSingleObservableAccess<T: Observable>(
        on object: T,
        keyPath: KeyPath<T, some Any>,
        when action: () -> Void
    ) async {
        let exp = expectation(description: "Wait for expectation")
        withObservationTracking {
            _ = object[keyPath: keyPath]
        } onChange: {
            // onChange is only called once per `withObservationTracking`
            exp.fulfill()
        }

        action()

        await fulfillment(of: [exp], timeout: 1.0)
    }
}
