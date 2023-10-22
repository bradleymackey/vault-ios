import Foundation
import FoundationExtensions
import TestHelpers
import XCTest
@testable import VaultFeed

@MainActor
final class DetailEditStateTests: XCTestCase {
    func test_init_hasNoSideEffects() {
        let delegate = MockDetailEditStateDelegate()
        _ = makeSUT(delegate: delegate)

        XCTAssertEqual(delegate.operationsPerformed, [])
    }

    func test_init_isInitiallyNotPerformingAnyOperations() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isSaving)
        XCTAssertFalse(sut.isInEditMode)
    }

    func test_startEditing_setsModeToEditing() {
        let sut = makeSUT()

        sut.startEditing()

        XCTAssertTrue(sut.isInEditMode)
    }

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

    func test_saveChanges_successSetsEditModeToFalse() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try await sut.saveChanges { /* noop */ }

        XCTAssertFalse(sut.isInEditMode)
    }

    func test_saveChanges_failureDoesNotChangeEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try? await sut.saveChanges { throw anyNSError() }

        XCTAssertTrue(sut.isInEditMode)
    }

    func test_saveChanges_failureThrowsError() async {
        let sut = makeSUT()

        await XCTAssertThrowsError(try await sut.saveChanges {
            throw anyNSError()
        })
    }

    func test_deleteItem_setsIsSavingToTrue() async throws {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for performDeletion")
        let pendingCall = PendingValue<Void>()
        // Save changes in a different task, so we don't suspend the current (test) task
        Task.detached(priority: .background) {
            try await sut.deleteItem {
                exp.fulfill()
                try? await pendingCall.awaitValue()
            } exitCurrentMode: {
                /* noop */
            }
        }

        await fulfillment(of: [exp])

        XCTAssertTrue(sut.isSaving)

        await pendingCall.fulfill()
    }

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
                        } exitCurrentMode: {
                            /* noop */
                        }
                    }
                }
            }
        }

        await fulfillment(of: [exp])

        await pendingCall.fulfill()
    }

    func test_deleteItem_successExitsCurrentMode() async throws {
        let sut = makeSUT()

        let expDelete = expectation(description: "Wait for perform deletion")
        let expExit = expectation(description: "Wait for exit current mode")
        try await sut.deleteItem {
            expDelete.fulfill()
        } exitCurrentMode: {
            expExit.fulfill()
        }

        await fulfillment(of: [expDelete, expExit], enforceOrder: true)
    }

    func test_deleteItem_failureDoesNotChangeEditMode() async throws {
        let sut = makeSUT()
        sut.startEditing()

        try? await sut.deleteItem {
            throw anyNSError()
        } exitCurrentMode: {
            // noop
        }

        XCTAssertTrue(sut.isInEditMode)
    }

    func test_deleteItem_failureThrowsError() async {
        let sut = makeSUT()

        await XCTAssertThrowsError(try await sut.deleteItem {
            throw anyNSError()
        } exitCurrentMode: {
            // noop
        })
    }

    func test_exitCurrentMode_clearsDirtyStateInEditMode() {
        let delegate = MockDetailEditStateDelegate()
        let sut = makeSUT(delegate: delegate)
        sut.startEditing()

        sut.exitCurrentMode()

        XCTAssertEqual(delegate.operationsPerformed, [.clearDirtyState])
    }

    func test_exitCurrentMode_disablesEditModeIfInEditMode() {
        let delegate = MockDetailEditStateDelegate()
        let sut = makeSUT(delegate: delegate)
        sut.startEditing()

        sut.exitCurrentMode()

        XCTAssertFalse(sut.isInEditMode)
    }

    func test_exitCurrentMode_existsCurrentModeIfNotInEditMode() {
        let delegate = MockDetailEditStateDelegate()
        let sut = makeSUT(delegate: delegate)

        sut.exitCurrentMode()

        XCTAssertEqual(delegate.operationsPerformed, [.exitCurrentMode])
    }
}

// MARK: - Helpers

extension DetailEditStateTests {
    typealias MockState = String

    private func makeSUT(
        delegate: MockDetailEditStateDelegate = MockDetailEditStateDelegate()
    ) -> DetailEditState<MockState> {
        let sut = DetailEditState<MockState>()
        sut.delegate = delegate
        return sut
    }

    private class MockDetailEditStateDelegate: DetailEditStateDelegate {
        enum Operation: Equatable {
            case clearDirtyState
            case exitCurrentMode
        }

        private(set) var operationsPerformed = [Operation]()

        var clearDirtyStateCalled: () -> Void = {}
        func clearDirtyState() {
            operationsPerformed.append(.clearDirtyState)
            clearDirtyStateCalled()
        }

        var exitCurrentModeCalled: () -> Void = {}
        func didExitCurrentMode() {
            operationsPerformed.append(.exitCurrentMode)
            exitCurrentModeCalled()
        }
    }
}
