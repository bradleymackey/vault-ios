import Foundation
import OTPSettings
import TestHelpers
import XCTest

final class LocalSettingsTests: XCTestCase {
    func test_objectWillChange_sendsOnValueChange() async throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        let publisher = sut.objectWillChange.collectFirst(3)

        let results: [Void] = try await awaitPublisher(publisher) {
            sut.state.previewSize = .large
            sut.state.previewSize = .medium
            sut.state.previewSize = .large
        }

        XCTAssertEqual(results.count, 3)
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
