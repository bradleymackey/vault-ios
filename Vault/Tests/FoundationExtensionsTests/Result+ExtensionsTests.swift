import Foundation
import FoundationExtensions
import Testing

struct ResultExtensionsTests {
    @Test
    func tryMap_mapsSuccess() {
        let initial: Result<Int, any Error> = .success(42)
        let mapped = initial.tryMap { _ in
            "mapped!"
        }

        switch mapped {
        case let .success(success):
            #expect(success == "mapped!")
        case .failure:
            Issue.record("Unexpected failure")
        }
    }

    @Test
    func asyncThrowingClosure_success() async {
        let result = await Result<Int, any Error> {
            try await someSuccessfulOperation()
        }

        switch result {
        case let .success(success):
            #expect(success == 42)
        case .failure:
            Issue.record("Unexpected failure")
        }
    }

    @Test
    func asyncThrowingClosure_failure() async {
        let result = await Result<Int, any Error> {
            try await someFailingOperation()
        }

        switch result {
        case .success:
            Issue.record("Unexpected success")
        case .failure:
            break
        }
    }
}

private func someSuccessfulOperation() async throws -> Int {
    42
}

private func someFailingOperation() async throws -> Int {
    struct ThisError: Error {}
    throw ThisError()
}
