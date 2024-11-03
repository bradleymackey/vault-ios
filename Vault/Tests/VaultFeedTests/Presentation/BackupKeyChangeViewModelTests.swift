import CryptoEngine
import Foundation
import FoundationExtensions
import TestHelpers
import VaultKeygen
import XCTest
@testable import VaultFeed

final class BackupKeyChangeViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = BackupPasswordStoreMock()
        let dataModel = anyVaultDataModel(backupPasswordStore: store)
        _ = makeSUT(dataModel: dataModel)

        XCTAssertEqual(store.fetchPasswordCallCount, 0)
        XCTAssertEqual(store.setCallCount, 0)
    }

    @MainActor
    func test_init_initialPermissionStateLoading() {
        let sut = makeSUT()

        XCTAssertEqual(sut.permissionState, .undetermined)
    }

    @MainActor
    func test_onAppear_permissonStateAllowedIfNoError() async {
        let authenticationService = DeviceAuthenticationService(policy: .alwaysAllow)
        let sut = makeSUT(authenticationService: authenticationService)

        await sut.onAppear()

        XCTAssertEqual(sut.permissionState, .allowed)
    }

    @MainActor
    func test_onAppear_permissionStateDeniedIfError() async {
        let authenticationService = DeviceAuthenticationService(policy: .alwaysDeny)
        let sut = makeSUT(authenticationService: authenticationService)

        await sut.onAppear()

        XCTAssertEqual(sut.permissionState, .denied)
    }

    @MainActor
    func test_loadExistingPassword_callsLoadFromDataModel() async {
        let store = BackupPasswordStoreMock()
        let password = randomBackupPassword()
        store.fetchPasswordHandler = { password }
        let dataModel = anyVaultDataModel(backupPasswordStore: store)
        let sut = makeSUT(dataModel: dataModel)

        await sut.loadExistingPassword()

        XCTAssertEqual(store.fetchPasswordCallCount, 1)
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
        let deriverFactory = VaultKeyDeriverFactoryMock()
        deriverFactory.makeVaultBackupKeyDeriverHandler = {
            VaultKeyDeriver(deriver: KeyDeriverErroring(), signature: .testing)
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
}

// MARK: - Helpers

extension BackupKeyChangeViewModelTests {
    @MainActor
    private func makeSUT(
        dataModel: VaultDataModel = VaultDataModel(
            vaultStore: VaultStoreStub(),
            vaultTagStore: VaultTagStoreStub(),
            vaultImporter: VaultStoreImporterMock(),
            vaultDeleter: VaultStoreDeleterMock(),
            vaultKillphraseDeleter: VaultStoreKillphraseDeleterMock(),
            backupPasswordStore: BackupPasswordStoreMock(),
            backupEventLogger: BackupEventLoggerMock()
        ),
        authenticationService: DeviceAuthenticationService =
            DeviceAuthenticationService(policy: DeviceAuthenticationPolicyAlwaysAllow()),
        deriverFactory: any VaultKeyDeriverFactory = .testing
    ) -> BackupKeyChangeViewModel {
        BackupKeyChangeViewModel(
            dataModel: dataModel,
            authenticationService: authenticationService,
            deriverFactory: deriverFactory
        )
    }

    private func anyBackupPassword() -> DerivedEncryptionKey {
        DerivedEncryptionKey(key: .repeating(byte: 0x45), salt: Data(), keyDervier: .testing)
    }

    private func randomBackupPassword() -> DerivedEncryptionKey {
        DerivedEncryptionKey(key: .random(), salt: Data(), keyDervier: .testing)
    }

    private struct KeyDeriverErroring: KeyDeriver {
        var uniqueAlgorithmIdentifier: String { "err" }

        func key(password _: Data, salt _: Data) throws -> KeyData<Bits256> {
            struct Err: Error {}
            throw Err()
        }
    }
}
