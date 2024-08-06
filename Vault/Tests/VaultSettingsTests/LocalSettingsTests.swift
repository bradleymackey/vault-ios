import Foundation
import FoundationExtensions
import TestHelpers
import VaultSettings
import XCTest

final class LocalSettingsTests: XCTestCase {
    @MainActor
    func test_pasteTimeToLive_sendsObservableChangeOnValueChange() async throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        await expectSingleMutation(observable: sut, keyPath: \.state.pasteTimeToLive) {
            sut.state.pasteTimeToLive = .init(duration: 100)
        }

        await expectSingleMutation(observable: sut, keyPath: \.state.pasteTimeToLive) {
            sut.state.pasteTimeToLive = .init(duration: 200)
        }
    }

    @MainActor
    func test_pasteTimeToLive_defaultsToDefaultValue() throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        XCTAssertEqual(sut.state.pasteTimeToLive, .default)
    }

    @MainActor
    func test_pasteTimeToLive_savesStateAfterStateChanged() throws {
        let defaults = try makeDefaults()
        let sutSave = try makeSUT(defaults: defaults)
        sutSave.state.pasteTimeToLive = .init(duration: 1234)

        let sutRetrieve = try makeSUT(defaults: defaults)
        XCTAssertEqual(sutRetrieve.state.pasteTimeToLive, .init(duration: 1234))
    }
}

// MARK: - Helpers

extension LocalSettingsTests {
    @MainActor
    private func makeSUT(defaults: Defaults) throws -> LocalSettings {
        let settings = LocalSettings(defaults: defaults)
        trackForMemoryLeaks(settings)
        return settings
    }

    private func makeDefaults() throws -> Defaults {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}

extension UserDefaults {
    private var allStoredKeys: [String] {
        dictionaryRepresentation().keys.map { $0 }
    }
}
