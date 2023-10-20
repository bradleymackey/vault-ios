import Foundation
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
}

// MARK: - Helpers

extension DetailEditStateTests {
    private func makeSUT(
        delegate: MockDetailEditStateDelegate = MockDetailEditStateDelegate()
    ) -> DetailEditState {
        let sut = DetailEditState()
        sut.delegate = delegate
        return sut
    }

    private class MockDetailEditStateDelegate: DetailEditStateDelegate {
        enum Operation: Equatable {
            case update
            case delete
            case clearDirtyState
            case exitCurrentMode
        }

        private(set) var operationsPerformed = [Operation]()

        var performUpdateCalled: () -> Void = {}
        func performUpdate() async throws {
            operationsPerformed.append(.update)
            performUpdateCalled()
        }

        var performDeletionCalled: () -> Void = {}
        func performDeletion() async throws {
            operationsPerformed.append(.delete)
            performDeletionCalled()
        }

        var clearDirtyStateCalled: () -> Void = {}
        func clearDirtyState() {
            operationsPerformed.append(.clearDirtyState)
            clearDirtyStateCalled()
        }

        var exitCurrentModeCalled: () -> Void = {}
        func exitCurrentMode() {
            operationsPerformed.append(.exitCurrentMode)
            exitCurrentModeCalled()
        }
    }
}
