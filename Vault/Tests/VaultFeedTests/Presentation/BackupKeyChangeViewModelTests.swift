import CryptoEngine
import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupKeyChangeViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.fetchPasswordCallCount, 0)
        XCTAssertEqual(store.setCallCount, 0)
    }

    @MainActor
    func test_init_existingPasswordInitialStateIsLoading() {
        let sut = makeSUT()

        XCTAssertEqual(sut.existingPassword, .loading)
    }

    @MainActor
    func test_loadInitialData_loadsKeyIfItExists() {
        let store = BackupPasswordStoreMock()
        let password = randomBackupPassword()
        store.fetchPasswordHandler = { password }
        let sut = makeSUT(store: store)

        sut.loadInitialData()

        XCTAssertEqual(sut.existingPassword, .hasExistingPassword(password))
    }

    @MainActor
    func test_loadInitialData_doesNotLoadKeyIfItDoesNotExist() {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = { nil }
        let sut = makeSUT(store: store)

        sut.loadInitialData()

        XCTAssertEqual(sut.existingPassword, .noExistingPassword)
    }

    @MainActor
    func test_saveEnteredPassword_isPasswordConfirmErrorIfPasswordsDoNotMatch() async {
        let sut = makeSUT()

        sut.newlyEnteredPassword = "hello"
        sut.newlyEnteredPasswordConfirm = "world"

        await sut.saveEnteredPassword()

        XCTAssertEqual(sut.newPassword, .passwordConfirmError)
    }

    @MainActor
    func test_saveEnteredPassword_isKeygenErrorIfGenerationError() async {
        let deriverFactory = ApplicationKeyDeriverFactoryMock()
        deriverFactory.makeApplicationKeyDeriverHandler = {
            ApplicationKeyDeriver(deriver: KeyDeriverErroring(), signature: .testing)
        }
        let sut = makeSUT(deriverFactory: deriverFactory)

        sut.newlyEnteredPassword = "hello"
        sut.newlyEnteredPasswordConfirm = "hello"

        await sut.saveEnteredPassword()

        XCTAssertEqual(sut.newPassword, .keygenError)
    }

    @MainActor
    func test_saveEnteredPassword_successSetsNewPasswordStateToSuccess() async {
        let sut = makeSUT()

        sut.newlyEnteredPassword = "hello"
        sut.newlyEnteredPasswordConfirm = "hello"

        await sut.saveEnteredPassword()

        XCTAssertEqual(sut.newPassword, .success)
    }

    @MainActor
    func test_saveEnteredPassword_successResetsEnteredPassword() async {
        let sut = makeSUT()

        sut.newlyEnteredPassword = "hello"
        sut.newlyEnteredPasswordConfirm = "hello"

        await sut.saveEnteredPassword()

        XCTAssertEqual(sut.newlyEnteredPassword, "", "resets password")
        XCTAssertEqual(sut.newlyEnteredPasswordConfirm, "", "resets password")
    }

    @MainActor
    func test_saveEnteredPassword_successUpdatesExistingPassword() async {
        let sut = makeSUT()

        sut.newlyEnteredPassword = "hello"
        sut.newlyEnteredPasswordConfirm = "hello"

        await sut.saveEnteredPassword()

        switch sut.existingPassword {
        case let .hasExistingPassword(pw):
            XCTAssertEqual(pw.salt.count, 48)
        default:
            XCTFail("Unexpected case")
        }
    }
}

// MARK: - Helpers

extension BackupKeyChangeViewModelTests {
    @MainActor
    private func makeSUT(
        store: BackupPasswordStoreMock = BackupPasswordStoreMock(),
        deriverFactory: any ApplicationKeyDeriverFactory = TestApplicationKeyDeriverFactory()
    ) -> BackupKeyChangeViewModel {
        BackupKeyChangeViewModel(store: store, deriverFactory: deriverFactory)
    }

    private func anyBackupPassword() -> BackupPassword {
        BackupPassword(key: Data(repeating: 0x45, count: 10), salt: Data())
    }

    private func randomBackupPassword() -> BackupPassword {
        BackupPassword(key: Data.random(count: 10), salt: Data())
    }

    private struct KeyDeriverErroring: KeyDeriver {
        var uniqueAlgorithmIdentifier: String { "err" }

        func key(password _: Data, salt _: Data) throws -> Data {
            struct Err: Error {}
            throw Err()
        }
    }
}
