import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultSettings

struct LocalSettingsTests {
    @Test
    func pasteTimeToLive_defaultsToDefaultValue() throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        #expect(sut.state.pasteTimeToLive == .default)
    }

    @Test
    func pasteTimeToLive_savesStateAfterStateChanged() throws {
        let defaults = try makeDefaults()
        let sutSave = try makeSUT(defaults: defaults)
        sutSave.state.pasteTimeToLive = .init(duration: 1234)

        let sutRetrieve = try makeSUT(defaults: defaults)
        #expect(sutRetrieve.state.pasteTimeToLive == .init(duration: 1234))
    }
}

// MARK: - Helpers

extension LocalSettingsTests {
    private func makeSUT(defaults: Defaults) throws -> LocalSettings {
        let settings = LocalSettings(defaults: defaults)
        return settings
    }

    private func makeDefaults() throws -> Defaults {
        let userDefaults = try #require(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}

extension UserDefaults {
    private var allStoredKeys: [String] {
        dictionaryRepresentation().keys.map { $0 }
    }
}
