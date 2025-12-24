import Foundation

// swiftlint:disable:next no_preconcurrency
@preconcurrency import AuthenticationServices
import VaultCore

/// The store which is used for autofilling OTP credentials on websites (iOS system integration).
///
/// This is required by the system in order to display offer up suggestions for autofilling.
/// The app extension can then be used to actually retrieve the value for the code (and the logic for this is managed
/// inside the extension).
///
/// ## recordIdentifier Policy
/// All credential identities use the VaultItem's UUID as the recordIdentifier (UUID.uuidString).
/// This provides a unique, stable identifier for each OTP credential and enables individual
/// management (add, update, remove) without affecting other credentials.
///
/// @mockable
public protocol VaultOTPAutofillStore: Sendable {
    /// Syncs a VaultItem to the autofill store.
    /// If the item is an OTP code, it will be added/updated. Otherwise, this is a no-op.
    func sync(id: UUID, item: VaultItem.Payload) async throws

    /// Removes a specific OTP credential identity by VaultItem UUID.
    /// Safe to call even if the item is not in the autofill store.
    func remove(id: UUID) async throws

    /// Removes all OTP credential identities from the store.
    func removeAll() async throws

    /// Gets all OTP credential identities currently in the store.
    /// - Throws: `CredentialIdentityStoreError.storeDisabled` if AutoFill is not enabled
    func getAllIdentities() async throws -> [ASOneTimeCodeCredentialIdentity]

    /// Gets the current state of the credential identity store.
    func getState() async -> ASCredentialIdentityStoreState
}

public final class VaultOTPAutofillStoreImpl: VaultOTPAutofillStore {
    private let store: any CredentialIdentityStore

    public init(store: any CredentialIdentityStore) {
        self.store = store
    }

    public func sync(id: UUID, item: VaultItem.Payload) async throws {
        guard let otpCode = item.otpCode else {
            // Not an OTP item, remove from autofill store if present
            try await remove(id: id)
            return
        }

        let identity = ASOneTimeCodeCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(
                identifier: otpCode.data.issuer,
                type: .domain,
            ),
            label: otpCode.data.accountName,
            recordIdentifier: id.uuidString,
        )
        try await store.saveCredentialIdentities([identity])
    }

    public func remove(id: UUID) async throws {
        // Create minimal identity with recordIdentifier for removal
        // Apple's API matches by recordIdentifier, so other fields don't matter
        let identity = ASOneTimeCodeCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(
                identifier: "",
                type: .domain,
            ),
            label: "",
            recordIdentifier: id.uuidString,
        )
        try await store.removeCredentialIdentities([identity])
    }

    public func removeAll() async throws {
        try await store.removeAllCredentialIdentities()
    }

    public func getAllIdentities() async throws -> [ASOneTimeCodeCredentialIdentity] {
        let identities = try await store.getCredentialIdentities()
        return identities.compactMap { $0 as? ASOneTimeCodeCredentialIdentity }
    }

    public func getState() async -> ASCredentialIdentityStoreState {
        await store.getState()
    }
}
