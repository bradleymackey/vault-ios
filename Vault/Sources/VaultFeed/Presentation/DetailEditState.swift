import Combine
import Foundation

/// Manages the edit/saving state for specific editing specific vault items.
@MainActor
@Observable
final class DetailEditState<T: Equatable> {
    private(set) var isSaving = false
    private(set) var isInEditMode = false

    var delegate: (any DetailEditStateDelegate)?

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

    func deleteItem(performDeletion: () async throws -> Void, exitCurrentMode: () -> Void) async throws {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await performDeletion()
            exitCurrentMode()
        } catch {
            throw OperationError.delete
        }
    }

    func exitCurrentMode() {
        if isInEditMode {
            delegate?.clearDirtyState()
            isInEditMode = false
        } else {
            delegate?.didExitCurrentMode()
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
                localized(key: "codeDetail.action.save.error.description")
            case .delete:
                localized(key: "codeDetail.action.delete.error.description")
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
