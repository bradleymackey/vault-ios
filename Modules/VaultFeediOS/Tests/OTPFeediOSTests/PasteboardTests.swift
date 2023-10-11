import Foundation
import VaultFeediOS
import XCTest

@MainActor
final class PasteboardTests: XCTestCase {
    func test_init_hasNoSideEffects() async throws {
        let pasteboard = MockSystemPasteboard()

        let exp = expectation(description: "Wait for pasteboard copy")
        exp.isInverted = true
        pasteboard.copyCalled = { _ in
            exp.fulfill()
        }

        _ = makeSUT(pasteboard: pasteboard)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_copy_copiesToPasteboard() async throws {
        let pasteboard = MockSystemPasteboard()
        let sut = makeSUT(pasteboard: pasteboard)
        let targetString = "hello world, this is my string"

        let exp = expectation(description: "Wait for pasteboard copy")
        pasteboard.copyCalled = { copiedString in
            XCTAssertEqual(copiedString, targetString)
            exp.fulfill()
        }

        sut.copy(targetString)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func test_copy_emitsDidPasteEvent() async throws {
        let sut = makeSUT()

        let output = sut.didPaste().collectFirst(3)
        _ = try await awaitPublisher(output) {
            sut.copy("any")
            sut.copy("any")
            sut.copy("any")
        }
    }
}

// MARK: - Helpers

extension PasteboardTests {
    private func makeSUT(pasteboard: MockSystemPasteboard = MockSystemPasteboard()) -> Pasteboard {
        Pasteboard(pasteboard)
    }

    private class MockSystemPasteboard: SystemPasteboard {
        var copyCalled: (String) -> Void = { _ in }
        func copy(string: String) {
            copyCalled(string)
        }
    }
}
