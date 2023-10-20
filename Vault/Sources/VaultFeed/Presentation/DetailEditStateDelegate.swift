import Foundation
import FoundationExtensions

protocol DetailEditStateDelegate {
    func performUpdate() async throws
    func performDeletion() async throws
    func clearDirtyState()
    func exitCurrentMode()
}

extension WeakBox: DetailEditStateDelegate where T: DetailEditStateDelegate {
    func performUpdate() async throws {
        try await value?.performUpdate()
    }

    func performDeletion() async throws {
        try await value?.performDeletion()
    }

    func clearDirtyState() {
        value?.clearDirtyState()
    }

    func exitCurrentMode() {
        value?.exitCurrentMode()
    }
}
