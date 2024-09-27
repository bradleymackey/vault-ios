import Foundation
import FoundationExtensions
import Testing

struct DefaultsStoredTests {
    @Test(arguments: [0, 1234, 456])
    func init_fallsBackToDefaultIfNoStoredValue(defaultValue: Int) throws {
        let defaults = try makeDefaults()

        @DefaultsStored(defaults: defaults, defaultsKey: .init("test1"), defaultValue: defaultValue)
        var coolNumber: Int

        #expect(coolNumber == defaultValue)
    }

    @Test(arguments: [4567, 0, 99999])
    func init_fetchesInitialValueStoredInDefaults(initialValue: Int) throws {
        let defaults = try makeDefaults()
        try defaults.set(initialValue, for: .init("test2"))

        @DefaultsStored(defaults: defaults, defaultsKey: .init("test2"), defaultValue: 1234)
        var coolNumber: Int

        #expect(coolNumber == initialValue)
    }

    @Test
    func test_wrappedValue_setsValueInDefaults() throws {
        let key: Key<Int> = .init("test3")
        let coolNumberInitial = 4567
        let defaults = try makeDefaults()
        try defaults.set(coolNumberInitial, for: key)

        @DefaultsStored(defaults: defaults, defaultsKey: key, defaultValue: 1234)
        var coolNumber: Int

        coolNumber = 9876

        #expect(coolNumber == 9876)

        let defaultsValue = try #require(defaults.get(for: key))
        #expect(defaultsValue == 9876)
    }
}

// MARK: - Helpers

extension DefaultsStoredTests {
    private func makeDefaults() throws -> Defaults {
        let userDefaults = try #require(UserDefaults(suiteName: #file))
        userDefaults.removePersistentDomain(forName: #file)
        return Defaults(userDefaults: userDefaults)
    }
}
