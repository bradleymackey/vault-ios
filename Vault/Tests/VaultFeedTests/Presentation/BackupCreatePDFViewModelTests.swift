import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class BackupCreatePDFViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        let backupPasswordStore = BackupPasswordStoreMock()
        _ = makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore, backupPasswordStore: backupPasswordStore)

        XCTAssertEqual(vaultStore.calledMethods, [])
        XCTAssertEqual(vaultTagStore.calledMethods, [])
        XCTAssertEqual(backupPasswordStore.fetchPasswordCallCount, 0)
        XCTAssertEqual(backupPasswordStore.setCallCount, 0)
    }

    @MainActor
    func test_init_initialStateIsIdle() {
        let sut = makeSUT()

        XCTAssertEqual(sut.state, .idle)
    }

    @MainActor
    func test_createPDF_makesPDFDocument() async {
        let vaultStore = VaultStoreStub()
        vaultStore.exportVaultHandler = { _ in
            .init(userDescription: "Hello", items: [], tags: [])
        }
        let sut = makeSUT(vaultStore: vaultStore)

        await sut.createPDF()

        XCTAssertEqual(sut.state, .success)
        XCTAssertNotNil(sut.createdDocument)
    }

    @MainActor
    func test_createPDF_recordsBackupEvent() async {
        let vaultStore = VaultStoreStub()
        vaultStore.exportVaultHandler = { _ in
            .init(userDescription: "Hello", items: [], tags: [])
        }
        let logger = BackupEventLoggerMock()
        let sut = makeSUT(vaultStore: vaultStore, backupEventLogger: logger)

        await sut.createPDF()

        XCTAssertEqual(logger.exportedToPDFCallCount, 1)
    }

    @MainActor
    func test_createPDF_errorSetsErrorState() async {
        let vaultStore = VaultStoreStub()
        vaultStore.exportVaultHandler = { _ in throw TestError() }
        let sut = makeSUT(vaultStore: vaultStore)

        await sut.createPDF()

        XCTAssertTrue(sut.state.isError)
        XCTAssertNil(sut.createdDocument)
    }
}

// MARK: - Helpers

extension BackupCreatePDFViewModelTests {
    @MainActor
    private func makeSUT(
        vaultStore: any VaultStore = VaultStoreStub(),
        vaultTagStore: any VaultTagStore = VaultTagStoreStub(),
        backupPasswordStore: any BackupPasswordStore = BackupPasswordStoreMock(),
        backupPassword: BackupPassword = anyBackupPassword(),
        clock: EpochClock = EpochClock(makeCurrentTime: { 100 }),
        backupEventLogger: any BackupEventLogger = BackupEventLoggerMock()
    ) -> BackupCreatePDFViewModel {
        BackupCreatePDFViewModel(
            backupPassword: backupPassword,
            dataModel: VaultDataModel(
                vaultStore: vaultStore,
                vaultTagStore: vaultTagStore,
                backupPasswordStore: backupPasswordStore
            ),
            clock: clock,
            backupEventLogger: backupEventLogger
        )
    }
}
