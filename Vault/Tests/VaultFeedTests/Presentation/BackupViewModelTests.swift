import Foundation
import TestHelpers
import XCTest
@testable import VaultFeed

final class BackupViewModelTests: XCTestCase {
    @MainActor
    func test_init_hasNoSideEffects() {
        let store = BackupPasswordStoreMock()
        _ = makeSUT(store: store)

        XCTAssertEqual(store.fetchPasswordCallCount, 0)
        XCTAssertEqual(store.setCallCount, 0)
    }

    @MainActor
    func test_fetchContent_setsStateToErrorIfError() {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            throw NSError(domain: "any", code: 100)
        }
        let sut = makeSUT(store: store)

        sut.fetchContent()

        XCTAssertEqual(sut.passwordState, .error)
    }

    @MainActor
    func test_fetchContent_setsToExistingPasswordIfOneExists() {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            BackupPassword(key: Data(), salt: Data())
        }
        let sut = makeSUT(store: store)

        sut.fetchContent()

        XCTAssertEqual(sut.passwordState, .hasExistingPassword)
    }

    @MainActor
    func test_fetchContent_setsToNoExistingPasswordIfOneDoesNotExists() {
        let store = BackupPasswordStoreMock()
        store.fetchPasswordHandler = {
            nil
        }
        let sut = makeSUT(store: store)

        sut.fetchContent()

        XCTAssertEqual(sut.passwordState, .noExistingPassword)
    }
}

// MARK: - Helpers

extension BackupViewModelTests {
    @MainActor
    private func makeSUT(store: BackupPasswordStoreMock = BackupPasswordStoreMock()) -> BackupViewModel {
        BackupViewModel(store: store)
    }
}
