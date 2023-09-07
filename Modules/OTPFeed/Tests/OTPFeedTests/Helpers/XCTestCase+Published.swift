import Combine
import Foundation
import XCTest

extension XCTestCase {
    /// Asserts that the given publisher completes before continuing.
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1,
        when perform: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T.Output {
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

        try await perform()

        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()

        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }

    /// Asserts that the given publisher does not output any values.
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

extension Published.Publisher {
    /// Collect the next *n* elements that are output, ignoring the first result
    func collectNext(_ count: Int) -> AnyPublisher<[Output], Never> {
        dropFirst()
            .collect(count)
            .first()
            .eraseToAnyPublisher()
    }

    /// For @Published, this is a publisher that ignores the first element.
    func nextElements() -> AnyPublisher<Output, Never> {
        dropFirst().eraseToAnyPublisher()
    }
}

extension Publisher {
    /// Collects the first *n* elements that are output.
    func collectFirst(_ count: Int) -> AnyPublisher<[Output], Failure> {
        collect(count)
            .first()
            .eraseToAnyPublisher()
    }
}
