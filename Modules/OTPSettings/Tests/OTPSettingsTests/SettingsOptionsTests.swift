import Foundation
import OTPSettings
import XCTest

final class SettingsOptionsTests: XCTestCase {
    func test_previewSize_defaultsToDefaultValue() throws {
        let (sut, _) = try makeSUT()

        XCTAssertEqual(sut.previewSize, .default)
    }

    func test_previewSize_savesAndRetrieves() throws {
        let (sut, userDefaults) = try makeSUT()

        XCTAssertFalse(userDefaults.allStoredKeys.contains("preview_size_v1"))

        sut.previewSize = .large

        XCTAssertTrue(userDefaults.allStoredKeys.contains("preview_size_v1"))
    }
}

// MARK: - Helpers

extension SettingsOptionsTests {
    private func makeSUT() throws -> (SettingsOptions, UserDefaults) {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)

        let defaults = Defaults(userDefaults: userDefaults)
        let sut = SettingsOptions(defaults: defaults)

        return (sut, userDefaults)
    }
}

private extension UserDefaults {
    var allStoredKeys: [String] {
        dictionaryRepresentation().keys.map { $0 }
    }
}
