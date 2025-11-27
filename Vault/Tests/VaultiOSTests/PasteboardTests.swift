import Foundation
import FoundationExtensions
import VaultSettings
import XCTest
@testable import VaultiOS

final class PasteboardTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() async throws {
        let pasteboard = SystemPasteboardMock()

        let exp = expectation(description: "Wait for pasteboard copy")
        exp.isInverted = true
        pasteboard.copyHandler = { _, _ in
            exp.fulfill()
        }

        _ = makeSUT(pasteboard: pasteboard)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_copy_copiesToPasteboard() async throws {
        let pasteboard = SystemPasteboardMock()
        let sut = makeSUT(pasteboard: pasteboard)
        let targetString = "hello world, this is my string"

        let exp = expectation(description: "Wait for pasteboard copy")
        pasteboard.copyHandler = { copiedString, _ in
            XCTAssertEqual(copiedString, targetString)
            exp.fulfill()
        }

        sut.copy(targetString)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    @MainActor
    func test_copy_emitsDidPasteEvent() async throws {
        let sut = makeSUT()

        let output = sut.didPaste().collectFirst(3)
        _ = try await awaitPublisher(output) {
            sut.copy("any")
            sut.copy("any")
            sut.copy("any")
        }
    }

    @MainActor
    func test_copy_usesTTLFromSettings() async throws {
        let ttl = PasteTTL(duration: 1234)
        let pasteboard = SystemPasteboardMock()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        settings.state.pasteTimeToLive = ttl

        let exp = expectation(description: "Wait for pasteboard copy")
        pasteboard.copyHandler = { _, actualTTL in
            XCTAssertEqual(actualTTL, ttl.duration)
            exp.fulfill()
        }

        sut.copy("some string")

        await fulfillment(of: [exp], timeout: 1.0)
    }
}

// MARK: - Helpers

extension PasteboardTests {
    @MainActor
    private func makeSUT(
        pasteboard: SystemPasteboardMock = SystemPasteboardMock(),
        localSettings: LocalSettings = LocalSettings(defaults: .init(userDefaults: .standard)),
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> Pasteboard {
        let pasteboard = Pasteboard(pasteboard, localSettings: localSettings)
        trackForMemoryLeaks(pasteboard, file: file, line: line)
        trackForMemoryLeaks(localSettings, file: file, line: line)
        return pasteboard
    }

    private func makeDefaults() throws -> Defaults {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}
