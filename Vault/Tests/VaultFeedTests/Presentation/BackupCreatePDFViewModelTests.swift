import Foundation
import TestHelpers
import VaultCore
import XCTest
@testable import VaultFeed

final class BackupCreatePDFViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() throws {
        let vaultStore = VaultStoreStub()
        let vaultTagStore = VaultTagStoreStub()
        let backupPasswordStore = BackupPasswordStoreMock()
        _ = try makeSUT(vaultStore: vaultStore, vaultTagStore: vaultTagStore, backupPasswordStore: backupPasswordStore)

        XCTAssertEqual(vaultStore.calledMethods, [])
        XCTAssertEqual(vaultTagStore.calledMethods, [])
        XCTAssertEqual(backupPasswordStore.fetchPasswordCallCount, 0)
        XCTAssertEqual(backupPasswordStore.setCallCount, 0)
    }

    @MainActor
    func test_init_initialStateIsIdle() throws {
        let sut = try makeSUT()

        XCTAssertEqual(sut.state, .idle)
    }

    @MainActor
    func test_createPDF_makesPDFDocument() async throws {
        let vaultStore = VaultStoreStub()
        vaultStore.exportVaultHandler = { _ in
            .init(userDescription: "Hello", items: [], tags: [])
        }
        let sut = try makeSUT(vaultStore: vaultStore)

        await sut.createPDF()

        XCTAssertEqual(sut.state, .success)
        XCTAssertNotNil(sut.generatedPDF)
    }

    @MainActor
    func test_createPDF_recordsBackupEvent() async throws {
        let vaultStore = VaultStoreStub()
        vaultStore.exportVaultHandler = { _ in
            .init(userDescription: "Hello", items: [], tags: [])
        }
        let logger = BackupEventLoggerMock()
        let sut = try makeSUT(vaultStore: vaultStore, backupEventLogger: logger)

        await sut.createPDF()

        XCTAssertEqual(logger.exportedToPDFCallCount, 1)
    }

    @MainActor
    func test_createPDF_errorSetsErrorState() async throws {
        let vaultStore = VaultStoreStub()
        vaultStore.exportVaultHandler = { _ in throw TestError() }
        let sut = try makeSUT(vaultStore: vaultStore)

        await sut.createPDF()

        XCTAssertTrue(sut.state.isError)
        XCTAssertNil(sut.generatedPDF)
    }
}

// MARK: - Helpers

extension BackupCreatePDFViewModelTests {
    @MainActor
    private func makeSUT(
        vaultStore: any VaultStore = VaultStoreStub(),
        vaultTagStore: any VaultTagStore = VaultTagStoreStub(),
        backupPasswordStore: any BackupPasswordStore = BackupPasswordStoreMock(),
        backupPassword: DerivedEncryptionKey = anyBackupPassword(),
        clock: some EpochClock = EpochClockMock(currentTime: 100),
        backupEventLogger: any BackupEventLogger = BackupEventLoggerMock()
    ) throws -> BackupCreatePDFViewModel {
        let defaults = try testUserDefaults()
        return BackupCreatePDFViewModel(
            backupPassword: backupPassword,
            dataModel: VaultDataModel(
                vaultStore: vaultStore,
                vaultTagStore: vaultTagStore,
                vaultImporter: VaultStoreImporterMock(),
                vaultDeleter: VaultStoreDeleterMock(),
                backupPasswordStore: backupPasswordStore,
                backupEventLogger: BackupEventLoggerMock()
            ),
            clock: clock,
            backupEventLogger: backupEventLogger,
            defaults: Defaults(userDefaults: defaults),
            fileManager: FileManager()
        )
    }
}
