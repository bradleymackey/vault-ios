import Foundation

// swiftlint:disable:next no_preconcurrency
@preconcurrency import AuthenticationServices
import VaultCore

/// The store which is used for autofilling OTP credentials on websites (iOS system integration).
///
/// This is required by the system in order to display offer up suggestions for autofilling.
/// The app extension can then be used to actually retrieve the value for the code (and the logic for this is managed
/// inside the extension).
/// @mockable
public protocol VaultOTPAutofillStore: Sendable {
    func update(
        id: UUID,
        code: OTPAuthCode,
    ) async throws
    func removeAll() async throws
}

public final class VaultOTPAutofillStoreImpl: VaultOTPAutofillStore {
    private let store: any CredentialIdentityStore

    public init(store: any CredentialIdentityStore) {
        self.store = store
    }

    public func update(
        id: UUID,
        code: OTPAuthCode,
    ) async throws {
        let serviceIdentifier = ASCredentialServiceIdentifier(
            identifier: code.data.issuer,
            type: .domain,
        )
        let identity = ASOneTimeCodeCredentialIdentity(
            serviceIdentifier: serviceIdentifier,
            label: code.data.accountName,
            recordIdentifier: id.uuidString,
        )
        try await store.replaceCredentialIdentities([identity])
    }

    public func removeAll() async throws {
        try await store.removeAllCredentialIdentities()
    }
}
