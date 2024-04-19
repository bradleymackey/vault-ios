import Foundation
import TestHelpers
import VaultSettings
import XCTest

final class LocalSettingsTests: XCTestCase {
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

    func test_pasteTimeToLive_defaultsToDefaultValue() throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        XCTAssertEqual(sut.state.pasteTimeToLive, .default)
    }

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
    private func makeSUT(defaults: Defaults) throws -> LocalSettings {
        LocalSettings(defaults: defaults)
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
