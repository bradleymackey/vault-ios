import Foundation
import TestHelpers
import VaultBackup
import XCTest
@testable import VaultFeed

final class BackupKeyDecryptorViewModelTests: XCTestCase {
    @MainActor
    func test_init_setsInitialState() {
        let sut = makeSUT()

        XCTAssertEqual(sut.enteredPassword, "")
        XCTAssertEqual(sut.generated, .none)
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
        let decoder = EncryptedVaultDecoderMock()
        decoder.verifyCanDecryptHandler = { _, _ in }
        let salt = Data(hex: "1234567890")
        let vault = anyEncryptedVault(salt: salt)
        let sut = makeSUT(encryptedVault: vault, keyDeriverFactory: .testing, encryptedVaultDecoder: decoder)
        sut.enteredPassword = "hello"

        await sut.attemptDecryption()

        // Some consistent key for the given dummy data above.
        let expectedKey = Data(hex: "b79f4462edd8d360b23fd70c1b0e39b0849e89fc51fb176742df837452e18518")
        let expected = try DerivedEncryptionKey(
            key: .init(data: expectedKey),
            salt: salt,
            keyDervier: .testing
        )
        XCTAssertEqual(sut.generated.generatedKey, expected)
    }

    @MainActor
    func test_generateKey_emptyPasswordGeneratesError() async {
        let decoder = EncryptedVaultDecoderMock()
        decoder.verifyCanDecryptHandler = { _, _ in throw TestError() }
        let sut = makeSUT(encryptedVaultDecoder: decoder)
        sut.enteredPassword = ""

        await sut.attemptDecryption()

        XCTAssertTrue(sut.generated.isError)
    }

    @MainActor
    func test_generateKey_keyDeriverErrorGeneratesError() async {
        let sut = makeSUT(keyDeriverFactory: .failing)
        sut.enteredPassword = "hello"

        await sut.attemptDecryption()

        XCTAssertTrue(sut.generated.isError)
    }
}

// MARK: - Helpers

extension BackupKeyDecryptorViewModelTests {
    @MainActor
    private func makeSUT(
        encryptedVault: EncryptedVault = anyEncryptedVault(),
        keyDeriverFactory: any VaultKeyDeriverFactory = VaultKeyDeriverFactoryTesting(),
        encryptedVaultDecoder: EncryptedVaultDecoderMock = EncryptedVaultDecoderMock()
    ) -> BackupKeyDecryptorViewModel {
        BackupKeyDecryptorViewModel(
            encryptedVault: encryptedVault,
            keyDeriverFactory: keyDeriverFactory,
            encryptedVaultDecoder: encryptedVaultDecoder
        )
    }
}
