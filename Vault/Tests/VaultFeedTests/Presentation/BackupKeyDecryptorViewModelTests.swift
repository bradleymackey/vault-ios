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
    func test_attemptDecryption_validPasswordGeneratesConsistentlyWithSalt() async throws {
        let decoder = EncryptedVaultDecoderMock()
        decoder.verifyCanDecryptHandler = { _, _ in }
        let sut = makeSUT(keyDeriver: .testing, encryptedVaultDecoder: decoder)
        sut.enteredPassword = "hello"
        let vault = anyEncryptedVault()

        await sut.attemptDecryption(encryptedVault: vault)

        // Some consistent key for the given dummy data above.
        let expectedKey = Data(hex: "b79f4462edd8d360b23fd70c1b0e39b0849e89fc51fb176742df837452e18518")
        let expected = try DerivedEncryptionKey(
            key: .init(data: expectedKey),
            salt: vault.keygenSalt,
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

        await sut.attemptDecryption(encryptedVault: anyEncryptedVault())

        XCTAssertTrue(sut.generated.isError)
    }

    @MainActor
    func test_generateKey_keyDeriverErrorGeneratesError() async {
        let sut = makeSUT(keyDeriver: .failing)
        sut.enteredPassword = "hello"

        await sut.attemptDecryption(encryptedVault: anyEncryptedVault())

        XCTAssertTrue(sut.generated.isError)
    }
}

// MARK: - Helpers

extension BackupKeyDecryptorViewModelTests {
    @MainActor
    private func makeSUT(
        keyDeriver: VaultKeyDeriver = .testing,
        encryptedVaultDecoder: EncryptedVaultDecoderMock = EncryptedVaultDecoderMock()
    ) -> BackupKeyDecryptorViewModel {
        BackupKeyDecryptorViewModel(keyDeriver: keyDeriver, encryptedVaultDecoder: encryptedVaultDecoder)
    }

    private func anyEncryptedVault() -> EncryptedVault {
        EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(hex: "1234567890"),
            keygenSignature: ""
        )
    }
}
