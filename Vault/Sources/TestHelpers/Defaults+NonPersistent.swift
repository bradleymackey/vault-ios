import Foundation
import FoundationExtensions

extension Defaults {
    enum NonPersistentError: Error {
        case cannotCreateUserDefaults
    }

    /// Creates non-persistent defaults in a unique domain to allow for use by parallel tests.
    public static func nonPersistent() throws -> Defaults {
        let suite = Data.random(count: 32).base64EncodedString()
        guard let userDefaults = UserDefaults(suiteName: suite) else {
            throw NonPersistentError.cannotCreateUserDefaults
        }
        userDefaults.removePersistentDomain(forName: suite)
        return Defaults(userDefaults: userDefaults)
    }
}
