import Foundation
import VaultSettings
import TestHelpers
import XCTest

final class LocalSettingsTests: XCTestCase {
    func test_previewSize_sendsObservableChangeOnValueChange() async throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        await expectSingleMutation(observable: sut, keyPath: \.state.previewSize) {
            sut.state.previewSize = .large
        }

        await expectSingleMutation(observable: sut, keyPath: \.state.previewSize) {
            sut.state.previewSize = .medium
        }
    }

    func test_previewSize_defaultsToDefaultValue() throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        XCTAssertEqual(sut.state.previewSize, .default)
    }

    func test_previewSize_savesStateAfterStateChanged() throws {
        let defaults = try makeDefaults()
        let sutSave = try makeSUT(defaults: defaults)
        sutSave.state.previewSize = .large

        let sutRetrieve = try makeSUT(defaults: defaults)
        XCTAssertEqual(sutRetrieve.state.previewSize, .large)
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

private extension UserDefaults {
    var allStoredKeys: [String] {
        dictionaryRepresentation().keys.map { $0 }
    }
}
