import Combine
import Foundation

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

    func saveChanges(performUpdate: () async throws -> Void) async throws {
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

    func deleteItem(performDeletion: () async throws -> Void, exitEditor: () -> Void) async throws {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await performDeletion()
            exitEditor()
        } catch {
            throw OperationError.delete
        }
    }

    func exitCurrentModeClearingDirtyState(clearDirtyState: () -> Void, exitEditor: () -> Void) {
        if isInEditMode {
            clearDirtyState()
            isInEditMode = false
        } else {
            exitEditor()
        }
    }
}

extension DetailEditState {
    enum OperationError: String, Error, Identifiable, LocalizedError, Equatable {
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

        var id: some Hashable {
            rawValue
        }
    }
}
