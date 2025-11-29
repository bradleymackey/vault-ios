import Combine
import Foundation
import FoundationExtensions
import XCTest

extension XCTestCase {
    /// Asserts that the given publisher completes before continuing.
    ///
    /// Your test will likely need to be isolated to the `MainActor` to ensure that
    /// we aren't passing values across isolation boundries whilst awaiting.
    @MainActor
    public func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1,
        when perform: @MainActor () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) async throws -> T.Output {
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
            },
        )

        try await perform()

        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()

        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line,
        )

        return try unwrappedResult.get()
    }

    /// Asserts that the given publisher does not output any values.
    ///
    /// Your test will likely need to be isolated to the `MainActor` to ensure that
    /// we aren't passing values across isolation boundries whilst awaiting.
    @MainActor
    public func awaitNoPublish(
        publisher: some Publisher,
        timeout: Double = 1.0,
        when perform: @MainActor () async throws -> Void,
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
    /// Creates a testing `confirmation` that a publisher will produce the given number of elements.
    @MainActor
    public func expect(
        publisher: some Publisher,
        valueCount: Int,
        when actions: sending @isolated(any) @escaping () async throws -> Void,
    ) async throws {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }
        let exp = expectation(description: "Wait for values")
        exp.expectedFulfillmentCount = valueCount
        cancellable = publisher.sink { _ in
            // noop
        } receiveValue: { _ in
            exp.fulfill()
        }
        Task { try await actions() }

        await fulfillment(of: [exp], timeout: 2.0)
    }
}
