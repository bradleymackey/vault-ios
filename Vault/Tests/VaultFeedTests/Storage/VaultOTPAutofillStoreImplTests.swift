import AuthenticationServices
import Foundation
import Testing
import VaultCore
@testable import VaultFeed

struct VaultOTPAutofillStoreImplTests {
    @Test(arguments: [
        ("", ""),
        ("tom@me.com", ""),
        ("", "issuer"),
        ("tom@me.com", "issuer"),
        ("tom@me.com", "issuer@example.com"),
    ])
    func update_createsIdentityWithCorrectIdentifiers(accountName: String, issuerName: String) async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)
        let id = UUID()
        let code = anyOTPAuthCode(
            accountName: accountName,
            issuerName: issuerName,
        )

        try await sut.update(id: id, code: code)

        let identities = try #require(spy.saveCredentialIdentitiesArgValues.first)
        let identity = try #require(identities.first as? ASOneTimeCodeCredentialIdentity)
        #expect(identity.recordIdentifier == id.uuidString)
        #expect(identity.serviceIdentifier.identifier == issuerName)
        #expect(identity.serviceIdentifier.type == .domain)
        #expect(identity.label == accountName)
    }

    @Test
    func update_savesSingleIdentity() async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)
        let id = UUID()
        let code = anyOTPAuthCode()

        try await sut.update(id: id, code: code)

        #expect(spy.saveCredentialIdentitiesCallCount == 1)
        let identities = try #require(spy.saveCredentialIdentitiesArgValues.first)
        #expect(identities.count == 1)
    }

    @Test
    func update_errorInStoreIsRethrown() async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)
        spy.saveCredentialIdentitiesHandler = { _ in
            throw TestError()
        }

        await #expect(throws: (any Error).self) {
            try await sut.update(id: UUID(), code: anyOTPAuthCode())
        }
    }

    @Test
    func remove_createsIdentityWithCorrectRecordIdentifier() async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)
        let id = UUID()

        try await sut.remove(id: id)

        let identities = try #require(spy.removeCredentialIdentitiesArgValues.first)
        let identity = try #require(identities.first as? ASOneTimeCodeCredentialIdentity)
        #expect(identity.recordIdentifier == id.uuidString)
    }

    @Test
    func remove_errorInStoreIsRethrown() async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)
        spy.removeCredentialIdentitiesHandler = { _ in
            throw TestError()
        }

        await #expect(throws: (any Error).self) {
            try await sut.remove(id: UUID())
        }
    }

    @Test
    func removeAll_callsStoreRemoveAll() async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)

        try await sut.removeAll()

        #expect(spy.removeAllCredentialIdentitiesCallCount == 1)
    }

    @Test
    func removeAll_errorInStoreIsRethrown() async throws {
        let spy = CredentialIdentityStoreMock()
        let sut = makeSUT(store: spy)
        spy.removeAllCredentialIdentitiesHandler = {
            throw TestError()
        }

        await #expect(throws: (any Error).self) {
            try await sut.removeAll()
        }
    }
}

// MARK: - Helpers

extension VaultOTPAutofillStoreImplTests {
    private func makeSUT(
        store: CredentialIdentityStoreMock = CredentialIdentityStoreMock(),
    ) -> VaultOTPAutofillStoreImpl {
        VaultOTPAutofillStoreImpl(store: store)
    }
}
