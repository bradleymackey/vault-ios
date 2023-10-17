import Combine
import XCTest

extension XCTestCase {
    func awaitNoPublish(
        publisher: some Publisher,
        timeout: Double = 1.0,
        when perform: () async throws -> Void
    ) async rethrows {
        var isFulfilled = false
        let expectation = expectation(description: "Wait for no publish")
        expectation.isInverted = true
        func fulfill() {
            if !isFulfilled {
                isFulfilled = true
                expectation.fulfill()
            }
        }
        let cancellable = publisher.sink(receiveCompletion: { _ in
            fulfill()
        }, receiveValue: { _ in
            fulfill()
        })

        try await perform()

        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()
    }
}

extension XCTestCase {
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        when operation: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, any Error>?
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

        operation()

        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }
}
