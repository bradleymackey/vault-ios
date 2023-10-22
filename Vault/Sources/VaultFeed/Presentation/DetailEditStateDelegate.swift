import Foundation
import FoundationExtensions

protocol DetailEditStateDelegate {
    func performDeletion() async throws
    func clearDirtyState()
    func didExitCurrentMode()
}

extension WeakBox: DetailEditStateDelegate where T: DetailEditStateDelegate {
    func performDeletion() async throws {
        try await value?.performDeletion()
    }

    func clearDirtyState() {
        value?.clearDirtyState()
    }

    func didExitCurrentMode() {
        value?.didExitCurrentMode()
    }
}
