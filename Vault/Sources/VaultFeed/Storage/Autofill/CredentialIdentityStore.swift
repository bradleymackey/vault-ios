import Foundation

// swiftlint:disable:next no_preconcurrency
@preconcurrency import AuthenticationServices

/// Thin wrapper around ASCredentialIdentityStore, allowing for mocking and injection.
///
/// @mockable
public protocol CredentialIdentityStore: Sendable {
    func replaceCredentialIdentities(_ newCredentials: [any ASCredentialIdentity]) async throws
    func removeAllCredentialIdentities() async throws
}

/// Real implementation that delegates to ASCredentialIdentityStore.shared
public final class RealCredentialIdentityStore: CredentialIdentityStore {
    private let store = ASCredentialIdentityStore.shared

    public init() {}

    public func replaceCredentialIdentities(_ newCredentials: [any ASCredentialIdentity]) async throws {
        try await store.replaceCredentialIdentities(newCredentials)
    }

    public func removeAllCredentialIdentities() async throws {
        try await store.removeAllCredentialIdentities()
    }
}
