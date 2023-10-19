import Foundation
import VaultSettings
import XCTest

final class DefaultsStoredTests: XCTestCase {
    func test_init_fallsBackToDefaultIfNoStoredValue() throws {
        let defaults = try makeDefaults()

        @DefaultsStored(defaults: defaults, defaultsKey: .init("test1"), defaultValue: 1234)
        var coolNumber: Int

        XCTAssertEqual(coolNumber, 1234)
    }

    func test_init_fetchesInitialValueStoredInDefaults() throws {
        let coolNumberInitial = 4567
        let defaults = try makeDefaults()
        try defaults.set(coolNumberInitial, for: .init("test2"))

        @DefaultsStored(defaults: defaults, defaultsKey: .init("test2"), defaultValue: 1234)
        var coolNumber: Int

        XCTAssertEqual(coolNumber, 4567)
    }

    func test_wrappedValue_setsValueInDefaults() throws {
        let key: Key<Int> = .init("test3")
        let coolNumberInitial = 4567
        let defaults = try makeDefaults()
        try defaults.set(coolNumberInitial, for: key)

        @DefaultsStored(defaults: defaults, defaultsKey: key, defaultValue: 1234)
        var coolNumber: Int

        coolNumber = 9876

        XCTAssertEqual(coolNumber, 9876)

        let defaultsValue = try XCTUnwrap(defaults.get(for: key))
        XCTAssertEqual(defaultsValue, 9876)
    }
}

// MARK: - Helpers

extension DefaultsStoredTests {
    private func makeDefaults() throws -> Defaults {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}
