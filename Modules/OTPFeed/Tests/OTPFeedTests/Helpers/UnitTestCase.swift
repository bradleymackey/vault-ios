import Combine
import Foundation
import XCTest

class UnitTestCase: XCTestCase {
    var testBag: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        testBag = []
    }

    override func tearDown() async throws {
        testBag = nil

        try await super.tearDown()
    }

    /// Creates an expectation that the given publisher will not publish any values.
    ///
    /// It's an inverted expectation, so don't make your timeouts too long.
    func expectationNoPublish(publisher: some Publisher) -> XCTestExpectation {
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
        }).store(in: &testBag)

        return exp
    }
}
