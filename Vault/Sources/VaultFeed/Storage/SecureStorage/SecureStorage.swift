import Foundation
import SwiftSecurity

/// Stores data securely on the device (most likely the keychain).
///
/// @mockable
public protocol SecureStorage: Sendable {
    /// Locally stores data with a restrictive access policy that requires
    /// user presence (biometric / passcode) at retrieval time.
    /// Overrides existing value if it exists.
    ///
    /// - Throws: Internal error is thrown if we cannot store to the Keychain.
    func store(data: Data, forKey key: String) async throws
    /// Returns `nil` if the data does not exist for this key.
    ///
    /// - Throws: Internal error is thrown if we cannot retrieve from the Keychain.
    func retrieve(key: String) async throws -> Data?

    /// Locally stores data with a less restrictive policy that does **not**
    /// require user presence — only that the device be unlocked. Use this
    /// for material that the app must read silently (e.g. the killphrase
    /// HMAC key, which has to be available without a biometric prompt so
    /// the silent-delete-on-search UX works).
    ///
    /// Overrides existing value if it exists.
    func storeSilent(data: Data, forKey key: String) async throws
    /// Silent retrieval counterpart. Returns `nil` if no data exists.
    func retrieveSilent(key: String) async throws -> Data?
}

public actor SecureStorageImpl: SecureStorage {
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

    public func storeSilent(data: Data, forKey key: String) throws {
        try keychain.remove(.credential(for: key))
        let accessPolicy = AccessPolicy(.whenUnlocked)
        try keychain.store(data, query: .credential(for: key), accessPolicy: accessPolicy)
    }

    public func retrieveSilent(key: String) throws -> Data? {
        try keychain.retrieve(.credential(for: key))
    }
}
