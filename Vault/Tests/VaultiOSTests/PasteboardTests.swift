import Foundation
import FoundationExtensions
import Testing
import VaultSettings
@testable import VaultiOS

@Suite
@MainActor
final class PasteboardTests {
    @Test
    func init_hasNoSideEffects() async throws {
        let pasteboard = SystemPasteboardMock()

        await confirmation(expectedCount: 0) { confirm in
            pasteboard.copyHandler = { _, _ in
                confirm()
            }

            _ = makeSUT(pasteboard: pasteboard)
        }
    }

    @Test
    func copy_copiesToPasteboard() async throws {
        let pasteboard = SystemPasteboardMock()
        let sut = makeSUT(pasteboard: pasteboard)
        let targetString = "hello world, this is my string"

        await confirmation { confirm in
            pasteboard.copyHandler = { copiedString, _ in
                #expect(copiedString == targetString)
                confirm()
            }

            sut.copy(targetString)
        }
    }

    @Test
    func copy_emitsDidPasteEvent() async throws {
        let sut = makeSUT()

        try await sut.didPaste().expect(valueCount: 3) {
            sut.copy("any")
            sut.copy("any")
            sut.copy("any")
        }
    }

    @Test
    func copy_usesTTLFromSettings() async throws {
        let ttl = PasteTTL(duration: 1234)
        let pasteboard = SystemPasteboardMock()
        let defaults = try makeDefaults()
        let settings = LocalSettings(defaults: defaults)
        let sut = makeSUT(pasteboard: pasteboard, localSettings: settings)

        settings.state.pasteTimeToLive = ttl

        await confirmation { confirm in
            pasteboard.copyHandler = { _, actualTTL in
                #expect(actualTTL == ttl.duration)
                confirm()
            }

            sut.copy("some string")
        }
    }
}

// MARK: - Helpers

extension PasteboardTests {
    private func makeSUT(
        pasteboard: SystemPasteboardMock = SystemPasteboardMock(),
        localSettings: LocalSettings = LocalSettings(defaults: .init(userDefaults: .standard)),
        file _: StaticString = #filePath,
        line _: UInt = #line,
    ) -> Pasteboard {
        let pasteboard = Pasteboard(pasteboard, localSettings: localSettings)
        return pasteboard
    }

    private func makeDefaults() throws -> Defaults {
        let userDefaults = try #require(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}
