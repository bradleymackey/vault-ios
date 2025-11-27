import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class EncryptedItemDetailViewModelTests: XCTestCase {
    @MainActor
    func test_canStartDecryption_isInitiallyFalse() {
        let sut = makeSUT(item: anyEncryptedItem())

        XCTAssertFalse(sut.canStartDecryption)
    }

    @MainActor
    func test_canStartDecryption_trueWhenPasswordIsEntered() {
        let sut = makeSUT(item: anyEncryptedItem())
        sut.enteredEncryptionPassword = "hello"

        XCTAssertTrue(sut.canStartDecryption)
    }

    @MainActor
    func test_state_isInitiallyBase() {
        let sut = makeSUT(item: anyEncryptedItem())

        XCTAssertEqual(sut.state, .base)
    }

    @MainActor
    func test_startDecryption_setsStateToDecrypting() async {
        let keyDeriverFactory = VaultKeyDeriverFactoryMock()
        var keyDeriver = SuspendingKeyDeriver<Bits256>()
        keyDeriverFactory.lookupVaultKeyDeriverHandler = { _ in .init(deriver: keyDeriver, signature: .testing) }
        let sut = makeSUT(item: anyEncryptedItem(), keyDeriverFactory: keyDeriverFactory)
        sut.enteredEncryptionPassword = "hello"

        let exp = expectation(description: "test")
        keyDeriver.startedKeyDerivationHandler = { _, _ in
            exp.fulfill()
            return .random()
        }
        Task.detached {
            await sut.startDecryption()
        }

        await fulfillment(of: [exp], timeout: 1)

        XCTAssertEqual(sut.state, .decrypting)

        keyDeriver.signalDerivationComplete()
    }

    @MainActor
    func test_startDecryption_secureNote() async throws {
        let note = SecureNote(title: "Hello", contents: "World", format: .plain)
        let derivedKey = try VaultKeyDeriver.testing.createEncryptionKey(password: "hello")
        let encryptor = VaultItemEncryptor(key: derivedKey)
        let encryptedItem = try encryptor.encrypt(item: note)

        let keyDeriverFactory = VaultKeyDeriverFactoryMock()
        keyDeriverFactory.lookupVaultKeyDeriverHandler = { _ in .testing }
        let sut = makeSUT(item: encryptedItem, keyDeriverFactory: keyDeriverFactory)
        sut.enteredEncryptionPassword = "hello"

        await sut.startDecryption()

        switch sut.state {
        case let .decrypted(.secureNote(decryptedNote), key):
            XCTAssertEqual(decryptedNote, note)
            XCTAssertEqual(key, derivedKey)
        default:
            XCTFail("Unexpected state \(sut.state)")
        }
    }

    @MainActor
    func test_startDecryption_unknownItem() async throws {
        let encryptable = VaultItemEncryptableMock(
            itemIdentifier: "this is invalid",
        )
        let derivedKey = try VaultKeyDeriver.testing.createEncryptionKey(password: "hello")
        let encryptor = VaultItemEncryptor(key: derivedKey)
        let encryptedItem = try encryptor.encrypt(item: encryptable)

        let keyDeriverFactory = VaultKeyDeriverFactoryMock()
        keyDeriverFactory.lookupVaultKeyDeriverHandler = { _ in .testing }
        let sut = makeSUT(item: encryptedItem, keyDeriverFactory: keyDeriverFactory)
        sut.enteredEncryptionPassword = "hello"

        await sut.startDecryption()

        switch sut.state {
        case let .decryptionError(error):
            XCTAssertEqual(error.userTitle, "Error")
            XCTAssertEqual(
                error.userDescription,
                "Your password was correct, but the item that was encrypted is not known to Vault. We can't display it.",
            )
        default:
            XCTFail("Unexpected state \(sut.state)")
        }
    }

    @MainActor
    func test_startDecryption_invalidPassword() async throws {
        let encryptable = VaultItemEncryptableMock(
            itemIdentifier: "any",
        )
        let derivedKey = try VaultKeyDeriver.testing.createEncryptionKey(password: "hello")
        let encryptor = VaultItemEncryptor(key: derivedKey)
        let encryptedItem = try encryptor.encrypt(item: encryptable)

        let keyDeriverFactory = VaultKeyDeriverFactoryMock()
        keyDeriverFactory.lookupVaultKeyDeriverHandler = { _ in .testing }
        let sut = makeSUT(item: encryptedItem, keyDeriverFactory: keyDeriverFactory)
        sut.enteredEncryptionPassword = "incorrect password"

        await sut.startDecryption()

        switch sut.state {
        case let .decryptionError(error):
            XCTAssertEqual(error.userTitle, "Incorrect Password")
            XCTAssertEqual(error.userDescription, "Your password was not recognized, please try again.")
        default:
            XCTFail("Unexpected state \(sut.state)")
        }
    }
}

// MARK: - Helpers

extension EncryptedItemDetailViewModelTests {
    @MainActor
    private func makeSUT(
        item: EncryptedItem,
        metadata: VaultItem.Metadata = anyVaultItemMetadata(),
        keyDeriverFactory: VaultKeyDeriverFactoryMock = VaultKeyDeriverFactoryMock(),
    ) -> EncryptedItemDetailViewModel {
        EncryptedItemDetailViewModel(item: item, metadata: metadata, keyDeriverFactory: keyDeriverFactory)
    }
}
