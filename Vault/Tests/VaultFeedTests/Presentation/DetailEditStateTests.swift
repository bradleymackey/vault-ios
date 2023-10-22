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
        let delegate = MockDetailEditStateDelegate()
        let sut = makeSUT(delegate: delegate)

        let exp = expectation(description: "Wait for performDeletion")
        let pendingCall = PendingValue<Void>()
        delegate.performDeletionCalled = {
            exp.fulfill()
            try? await pendingCall.awaitValue()
        }

        // Save changes in a different task, so we don't suspend the current (test) task
        Task.detached(priority: .background) {
            try await sut.deleteItem()
        }

        await fulfillment(of: [exp])

        XCTAssertTrue(sut.isSaving)

        await pendingCall.fulfill()
    }

    func test_deleteItem_hasNoEffectIfCalledWhileExistingSaveInProgress() async throws {
        let delegate = MockDetailEditStateDelegate()
        let sut = makeSUT(delegate: delegate)

        let exp = expectation(description: "Wait for performDeletion")
        let pendingCall = PendingValue<Void>()
        delegate.performDeletionCalled = {
            exp.fulfill()
            try? await pendingCall.awaitValue()
        }

        Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 3 {
                    // Multiple calls being made, concurrently.
                    group.addTask {
                        try? await sut.deleteItem()
                    }
                }
            }
        }

        await fulfillment(of: [exp])

        XCTAssertEqual(delegate.operationsPerformed, [.delete], "Only a single deletion should be performed.")

        await pendingCall.fulfill()
    }

    func test_deleteItem_successExitsCurrentMode() async throws {
        let delegate = MockDetailEditStateDelegate()
        delegate.performDeletionResult = .success(())
        let sut = makeSUT(delegate: delegate)

        try await sut.deleteItem()

        XCTAssertEqual(delegate.operationsPerformed, [.delete, .exitCurrentMode])
    }

    func test_deleteItem_failureDoesNotChangeEditMode() async throws {
        let delegate = MockDetailEditStateDelegate()
        delegate.performDeletionResult = .failure(anyNSError())
        let sut = makeSUT(delegate: delegate)
        sut.startEditing()

        try? await sut.deleteItem()

        XCTAssertEqual(delegate.operationsPerformed, [.delete])
    }

    func test_deleteItem_failureThrowsError() async {
        let delegate = MockDetailEditStateDelegate()
        delegate.performDeletionResult = .failure(anyNSError())
        let sut = makeSUT(delegate: delegate)

        await XCTAssertThrowsError(try await sut.deleteItem())
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
            case delete
            case clearDirtyState
            case exitCurrentMode
        }

        private(set) var operationsPerformed = [Operation]()

        var performDeletionResult: Result<Void, any Error> = .success(())
        var performDeletionCalled: () async -> Void = {}
        func performDeletion() async throws {
            operationsPerformed.append(.delete)
            await performDeletionCalled()
            try performDeletionResult.get()
        }

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
