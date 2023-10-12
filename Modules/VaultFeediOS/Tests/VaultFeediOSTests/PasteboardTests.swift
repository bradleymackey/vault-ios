import Foundation
import VaultFeediOS
import VaultSettings
import XCTest

@MainActor
final class PasteboardTests: XCTestCase {
    func test_init_hasNoSideEffects() async throws {
        let pasteboard = MockSystemPasteboard()

        let exp = expectation(description: "Wait for pasteboard copy")
        exp.isInverted = true
        pasteboard.copyCalled = { _, _ in
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
        pasteboard.copyCalled = { copiedString, _ in
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

    func test_copy_usesTTLFromSettings() async throws {
        let ttl = PasteTTL(duration: 1234)
        let pasteboard = MockSystemPasteboard()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        settings.state.pasteTimeToLive = ttl

        let exp = expectation(description: "Wait for pasteboard copy")
        pasteboard.copyCalled = { _, actualTTL in
            XCTAssertEqual(actualTTL, ttl.duration)
            exp.fulfill()
        }

        sut.copy("some string")

        await fulfillment(of: [exp], timeout: 1.0)
    }
}

// MARK: - Helpers

extension PasteboardTests {
    private func makeSUT(
        pasteboard: MockSystemPasteboard = MockSystemPasteboard(),
        localSettings: LocalSettings = LocalSettings(defaults: .init(userDefaults: .standard))
    ) -> Pasteboard {
        Pasteboard(pasteboard, localSettings: localSettings)
    }

    private class MockSystemPasteboard: SystemPasteboard {
        var copyCalled: (String, Double?) -> Void = { _, _ in }
        func copy(string: String, ttl: Double?) {
            copyCalled(string, ttl)
        }
    }

    private func makeDefaults() throws -> Defaults {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}
