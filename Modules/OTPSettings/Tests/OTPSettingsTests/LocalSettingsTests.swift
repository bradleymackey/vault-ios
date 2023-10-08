import Foundation
import OTPSettings
import TestHelpers
import XCTest

final class LocalSettingsTests: XCTestCase {
    func test_previewSize_sendsObservableChangeOnValueChange() async throws {
        let defaults = try makeDefaults()
        let sut = try makeSUT(defaults: defaults)

        let exp1 = expectation(description: "Wait for first change")
        withObservationTracking {
            let _ = sut.state.previewSize
        } onChange: {
            exp1.fulfill()
        }

        sut.state.previewSize = .large
        await fulfillment(of: [exp1], timeout: 1.0)

        let exp2 = expectation(description: "Wait for second change")
        withObservationTracking {
            let _ = sut.state.previewSize
        } onChange: {
            exp2.fulfill()
        }

        sut.state.previewSize = .medium
        await fulfillment(of: [exp2], timeout: 1.0)
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
