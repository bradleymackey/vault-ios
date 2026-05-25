import Combine
import Foundation
import TestHelpers
import Testing
import VaultBackup
import VaultKeygen
@testable import VaultFeed

@Suite
@MainActor
struct BackupKeyDecryptorViewModelTests {
    @Test
    func init_setsInitialState() {
        let sut = makeSUT()

        #expect(sut.enteredPassword == "")
        #expect(sut.decryptionKeyState == .none)
    }

    @Test
    func canAttemptDecryption_falseIfPasswordEmpty() async throws {
        let sut = makeSUT()
        sut.enteredPassword = ""

        #expect(sut.canAttemptDecryption == false)
    }

    @Test
    func canAttemptDecryption_trueIfPasswordNotEmpty() async throws {
        let sut = makeSUT()
        sut.enteredPassword = "a"

        #expect(sut.canAttemptDecryption)
    }

    @Test
    func attemptDecryption_validPasswordGeneratesConsistentlyWithSalt() async throws {
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
            decryptedVaultSubject: subject,
        )
        sut.enteredPassword = "hello"

        await confirmation { confirmation in
            let cancel = subject.sink { payload in
                #expect(payload == vaultApplicationPayload)
                confirmation.confirm()
            }

            await sut.attemptDecryption()

            cancel.cancel()
        }

        #expect(sut.decryptionKeyState == .validDecryptionKey)
    }

    @Test
    func generateKey_emptyPasswordGeneratesError() async {
        let decoder = EncryptedVaultDecoderMock()
        decoder.verifyCanDecryptHandler = { _, _ in throw TestError() }
        let sut = makeSUT(encryptedVaultDecoder: decoder)
        sut.enteredPassword = ""

        await sut.attemptDecryption()

        #expect(sut.decryptionKeyState.isError)
    }

    @Test
    func generateKey_keyDeriverErrorGeneratesError() async {
        let sut = makeSUT(keyDeriverFactory: .failing)
        sut.enteredPassword = "hello"

        await sut.attemptDecryption()

        #expect(sut.decryptionKeyState.isError)
    }
}

// MARK: - Helpers

extension BackupKeyDecryptorViewModelTests {
    @MainActor
    private func makeSUT(
        encryptedVault: EncryptedVault = anyEncryptedVault(),
        keyDeriverFactory: any VaultKeyDeriverFactory = VaultKeyDeriverFactoryTesting(),
        encryptedVaultDecoder: EncryptedVaultDecoderMock = EncryptedVaultDecoderMock(),
        decryptedVaultSubject: PassthroughSubject<VaultApplicationPayload, Never> = .init(),
    ) -> BackupKeyDecryptorViewModel {
        BackupKeyDecryptorViewModel(
            encryptedVault: encryptedVault,
            keyDeriverFactory: keyDeriverFactory,
            encryptedVaultDecoder: encryptedVaultDecoder,
            decryptedVaultSubject: decryptedVaultSubject,
        )
    }
}
