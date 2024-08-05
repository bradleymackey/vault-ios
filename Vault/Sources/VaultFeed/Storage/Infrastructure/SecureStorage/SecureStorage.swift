import Foundation
import SwiftSecurity

/// Stores data securely on the device (most likely the keychain).
///
/// @mockable
public protocol SecureStorage {
    /// Locally stores data with a restrictive access policy.
    ///
    /// - Throws: Internal error is thrown if we cannot retrieve from the Keychain.
    func store(data: Data, forKey key: String) throws
    /// Returns `nil` if the data does not exist for this key.
    ///
    /// - Throws: Internal error is thrown if we cannot retrieve from the Keychain.
    func retrieve(key: String) throws -> Data?
}

public final class SecureStorageImpl: SecureStorage {
    private let keychain: Keychain

    public init(keychain: Keychain) {
        self.keychain = keychain
    }

    public func store(data: Data, forKey key: String) throws {
        try keychain.remove(.credential(for: key))
        let accessPolicy = AccessPolicy(.whenUnlocked, options: [.userPresence])
        try keychain.store(data, query: .credential(for: key), accessPolicy: accessPolicy)
    }

    public func retrieve(key: String) throws -> Data? {
        try keychain.retrieve(.credential(for: key))
    }
}
