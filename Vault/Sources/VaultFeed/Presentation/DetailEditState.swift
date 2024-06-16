import Combine
import Foundation
import FoundationExtensions

/// Manages the edit/saving state for specific editing specific vault items.
@MainActor
@Observable
final class DetailEditState<T: Equatable> {
    private(set) var isSaving = false
    private(set) var isInEditMode = false

    init() {}

    func startEditing() {
        isInEditMode = true
    }

    func saveChanges(performUpdate: @MainActor () async throws -> Void) async throws {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await performUpdate()
            isInEditMode = false
        } catch {
            throw OperationError.save
        }
    }

    func deleteItem(performDeletion: @MainActor () async throws -> Void, finished: @MainActor () -> Void) async throws {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await performDeletion()
            finished()
        } catch {
            throw OperationError.delete
        }
    }

    func exitCurrentModeClearingDirtyState(clearDirtyState: @MainActor () -> Void, finished: @MainActor () -> Void) {
        if isInEditMode {
            clearDirtyState()
            isInEditMode = false
        } else {
            finished()
        }
    }
}

extension DetailEditState {
    enum OperationError: Error, LocalizedError, Equatable, IdentifiableSelf {
        case save
        case delete

        var description: String {
            switch self {
            case .save:
                localized(key: "detail.operationError.save.description")
            case .delete:
                localized(key: "detail.operationError.delete.description")
            }
        }

        var errorDescription: String? {
            description
        }
    }
}
