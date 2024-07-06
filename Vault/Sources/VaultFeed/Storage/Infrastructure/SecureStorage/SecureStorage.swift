import Foundation
import SwiftSecurity

/// Stores data securely on the device (most likely the keychain).
///
/// @mockable
public protocol SecureStorage {
    func store(data: Data, forKey key: String) throws
    /// Returns `nil` if data is already present.
    func retrieve(key: String) throws -> Data?
}

public final class SecureStorageImpl: SecureStorage {
    private let keychain: Keychain

    public init(keychain: Keychain) {
        self.keychain = keychain
    }

    public func store(data: Data, forKey key: String) throws {
        let accessPolicy = AccessPolicy(.whenUnlockedThisDeviceOnly, options: [.userPresence])
        try keychain.store(data, query: .credential(for: key), accessPolicy: accessPolicy)
    }

    public func retrieve(key: String) throws -> Data? {
        try keychain.retrieve(.credential(for: key))
    }
}
