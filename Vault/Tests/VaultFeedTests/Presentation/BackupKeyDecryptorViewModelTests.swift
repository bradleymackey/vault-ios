import Combine
import Foundation
import TestHelpers
import VaultBackup
import VaultKeygen
import XCTest
@testable import VaultFeed

final class BackupKeyDecryptorViewModelTests: XCTestCase {
    @MainActor
    func test_init_setsInitialState() {
        let sut = makeSUT()

        XCTAssertEqual(sut.enteredPassword, "")
        XCTAssertEqual(sut.decryptionKeyState, .none)
    }

    @MainActor
    func test_canAttemptDecryption_falseIfPasswordEmpty() async throws {
        let sut = makeSUT()
        sut.enteredPassword = ""

        XCTAssertFalse(sut.canAttemptDecryption)
    }

    @MainActor
    func test_canAttemptDecryption_trueIfPasswordNotEmpty() async throws {
        let sut = makeSUT()
        sut.enteredPassword = "a"

        XCTAssertTrue(sut.canAttemptDecryption)
    }

    @MainActor
    func test_attemptDecryption_validPasswordGeneratesConsistentlyWithSalt() async throws {
        let vaultApplicationPayload = VaultApplicationPayload(userDescription: "my stuff", items: [], tags: [])
        let decoder = EncryptedVaultDecoderMock()
        // returned payload implies successful decryption
        decoder.decryptAndDecodeHandler = { _, _ in vaultApplicationPayload }
        let salt = Data(hex: "1234567890")
        let vault = anyEncryptedVault(salt: salt)
        let subject = PassthroughSubject<VaultApplicationPayload, Never>()
        let sut = makeSUT(
            encryptedVault: vault,
            keyDeriverFactory: .testing,
            encryptedVaultDecoder: decoder,
            decryptedVaultSubject: subject
        )
        sut.enteredPassword = "hello"

        let exp = expectation(description: "Wait for application payload")
        let cancel = subject.sink { payload in
            XCTAssertEqual(payload, vaultApplicationPayload)
            exp.fulfill()
        }

        await sut.attemptDecryption()

        await fulfillment(of: [exp], timeout: 1)

        XCTAssertEqual(sut.decryptionKeyState, .validDecryptionKey)

        cancel.cancel()
    }

    @MainActor
    func test_generateKey_emptyPasswordGeneratesError() async {
        let decoder = EncryptedVaultDecoderMock()
        decoder.verifyCanDecryptHandler = { _, _ in throw TestError() }
        let sut = makeSUT(encryptedVaultDecoder: decoder)
        sut.enteredPassword = ""

        await sut.attemptDecryption()

        XCTAssertTrue(sut.decryptionKeyState.isError)
    }

    @MainActor
    func test_generateKey_keyDeriverErrorGeneratesError() async {
        let sut = makeSUT(keyDeriverFactory: .failing)
        sut.enteredPassword = "hello"

        await sut.attemptDecryption()

        XCTAssertTrue(sut.decryptionKeyState.isError)
    }
}

// MARK: - Helpers

extension BackupKeyDecryptorViewModelTests {
    @MainActor
    private func makeSUT(
        encryptedVault: EncryptedVault = anyEncryptedVault(),
        keyDeriverFactory: any VaultKeyDeriverFactory = VaultKeyDeriverFactoryTesting(),
        encryptedVaultDecoder: EncryptedVaultDecoderMock = EncryptedVaultDecoderMock(),
        decryptedVaultSubject: PassthroughSubject<VaultApplicationPayload, Never> = .init()
    ) -> BackupKeyDecryptorViewModel {
        BackupKeyDecryptorViewModel(
            encryptedVault: encryptedVault,
            keyDeriverFactory: keyDeriverFactory,
            encryptedVaultDecoder: encryptedVaultDecoder,
            decryptedVaultSubject: decryptedVaultSubject
        )
    }
}
