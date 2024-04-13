import Foundation
import FoundationExtensions
import TestHelpers
import XCTest
@testable import VaultFeed

final class DetailEditStateTests: XCTestCase {
    @MainActor
    func test_init_isInitiallyNotPerformingAnyOperations() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isSaving)
        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_startEditing_setsModeToEditing() {
        let sut = makeSUT()

        sut.startEditing()

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_saveChanges_setsIsSavingToTrue() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for performUpdate")
        let pendingCall = PendingValue<Void>()
        // Save changes in a different task, so we don't suspend the current (test) task
        Task.detached(priority: .background) {
            try await sut.saveChanges {
                exp.fulfill()
                try? await pendingCall.awaitValue()
            }
        }

        await fulfillment(of: [exp])

        XCTAssertTrue(sut.isSaving)

        await pendingCall.fulfill()
    }

    @MainActor
    func test_saveChanges_hasNoEffectIfCalledWhileExistingSaveInProgress() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for performUpdate")
        let pendingCall = PendingValue<Void>()
        Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 3 {
                    // Multiple calls being made, concurrently.
                    group.addTask {
                        try? await sut.saveChanges {
                            exp.fulfill()
                            try? await pendingCall.awaitValue()
                        }
                    }
                }
            }
        }

        await fulfillment(of: [exp])

        await pendingCall.fulfill()
    }

    @MainActor
    func test_saveChanges_successSetsEditModeToFalse() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try await sut.saveChanges { /* noop */ }

        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_saveChanges_failureDoesNotChangeEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try? await sut.saveChanges { throw anyNSError() }

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_saveChanges_failureThrowsError() async {
        let sut = makeSUT()

        await XCTAssertThrowsError(try await sut.saveChanges {
            throw anyNSError()
        })
    }

    @MainActor
    func test_deleteItem_setsIsSavingToTrue() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for performDeletion")
        let pendingCall = PendingValue<Void>()
        // Save changes in a different task, so we don't suspend the current (test) task
        Task.detached(priority: .background) {
            try await sut.deleteItem {
                exp.fulfill()
                try? await pendingCall.awaitValue()
            } exitEditor: {
                /* noop */
            }
        }

        await fulfillment(of: [exp])

        XCTAssertTrue(sut.isSaving)

        await pendingCall.fulfill()
    }

    @MainActor
    func test_deleteItem_hasNoEffectIfCalledWhileExistingSaveInProgress() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for performDeletion")
        let pendingCall = PendingValue<Void>()
        Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 3 {
                    // Multiple calls being made, concurrently.
                    group.addTask {
                        try? await sut.deleteItem {
                            exp.fulfill()
                            try? await pendingCall.awaitValue()
                        } exitEditor: {
                            /* noop */
                        }
                    }
                }
            }
        }

        await fulfillment(of: [exp])

        await pendingCall.fulfill()
    }

    @MainActor
    func test_deleteItem_successExitsEditor() async throws {
        let sut = makeSUT()

        let expDelete = expectation(description: "Wait for perform deletion")
        let expExit = expectation(description: "Wait for exit current mode")
        try await sut.deleteItem {
            expDelete.fulfill()
        } exitEditor: {
            expExit.fulfill()
        }

        await fulfillment(of: [expDelete, expExit], enforceOrder: true)
    }

    @MainActor
    func test_deleteItem_failureDoesNotExitEditor() async throws {
        let sut = makeSUT()

        var exited = false
        try? await sut.deleteItem {
            throw anyNSError()
        } exitEditor: {
            exited = false
        }

        XCTAssertFalse(exited)
    }

    @MainActor
    func test_deleteItem_failureDoesNotChangeEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try? await sut.deleteItem {
            throw anyNSError()
        } exitEditor: {
            // noop
        }

        XCTAssertTrue(sut.isInEditMode)
    }

    @MainActor
    func test_deleteItem_failureThrowsError() async {
        let sut = makeSUT()

        await XCTAssertThrowsError(try await sut.deleteItem {
            throw anyNSError()
        } exitEditor: {
            // noop
        })
    }

    @MainActor
    func test_exitCurrentModeClearingDirtyState_clearsDirtyStateInEditMode() {
        let sut = makeSUT()
        sut.startEditing()

        var clearedState = false
        var exitedEditor = false
        sut.exitCurrentModeClearingDirtyState {
            clearedState = true
        } exitEditor: {
            exitedEditor = true
        }

        XCTAssertTrue(clearedState)
        XCTAssertFalse(exitedEditor, "Should not have exited editor")
    }

    @MainActor
    func test_exitCurrentModeClearingDirtyState_disablesEditModeIfInEditMode() {
        let sut = makeSUT()
        sut.startEditing()

        sut.exitCurrentModeClearingDirtyState {
            // noop
        } exitEditor: {
            // noop
        }

        XCTAssertFalse(sut.isInEditMode)
    }

    @MainActor
    func test_exitCurrentModeClearingDirtyState_existsCurrentModeIfNotInEditMode() {
        let sut = makeSUT()

        var clearedState = false
        var exitedEditor = false
        sut.exitCurrentModeClearingDirtyState {
            clearedState = true
        } exitEditor: {
            exitedEditor = true
        }

        XCTAssertTrue(exitedEditor)
        XCTAssertFalse(clearedState, "Should not have cleared state")
    }
}

// MARK: - Helpers

extension DetailEditStateTests {
    typealias MockState = String

    @MainActor
    private func makeSUT() -> DetailEditState<MockState> {
        DetailEditState<MockState>()
    }
}
