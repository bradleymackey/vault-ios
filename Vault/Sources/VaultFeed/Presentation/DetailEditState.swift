import Combine
import Foundation

/// Manages the edit/saving state for specific editing specific vault items.
@MainActor
@Observable
final class DetailEditState<T: Equatable> {
    private(set) var isSaving = false
    private(set) var isInEditMode = false

    private let editingModel: DetailEditingModel<T>
    var delegate: (any DetailEditStateDelegate)?

    init(editingModel: DetailEditingModel<T>) {
        self.editingModel = editingModel
    }

    func startEditing() {
        isInEditMode = true
    }

    func saveChanges() async throws {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await delegate?.performUpdate()
            editingModel.didPersist()
            isInEditMode = false
        } catch {
            throw OperationError.save
        }
    }

    func deleteItem() async throws {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await delegate?.performDeletion()
            delegate?.exitCurrentMode()
        } catch {
            throw OperationError.delete
        }
    }

    func exitCurrentMode() {
        if isInEditMode {
            delegate?.clearDirtyState()
            editingModel.restoreInitialState()
            isInEditMode = false
        } else {
            delegate?.exitCurrentMode()
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
