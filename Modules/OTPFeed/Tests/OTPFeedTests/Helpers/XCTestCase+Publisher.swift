import Combine
import Foundation
import XCTest

extension XCTestCase {
    /// Creates an expectation that the given publisher will not publish any values.
    ///
    /// It's an inverted expectation, so don't make your timeouts too long.
    func expectationNoPublish(publisher: some Publisher, bag: inout Set<AnyCancellable>) -> XCTestExpectation {
        var isFulfilled = false
        let exp = expectation(description: "Wait for no publish")
        exp.isInverted = true
        publisher.sink(receiveCompletion: { _ in
            // noop
        }, receiveValue: { _ in
            if !isFulfilled {
                isFulfilled = true
                exp.fulfill()
            }
        }).store(in: &bag)

        return exp
    }
}
