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

extension XCTestCase {
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1,
        when perform: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        var result: Result<T.Output, Error>?
        let expectation = expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        perform()

        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }
}
