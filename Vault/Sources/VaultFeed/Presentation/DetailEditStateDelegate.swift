import Foundation
import FoundationExtensions

protocol DetailEditStateDelegate {
    func clearDirtyState()
    func didExitCurrentMode()
}

extension WeakBox: DetailEditStateDelegate where T: DetailEditStateDelegate {
    func clearDirtyState() {
        value?.clearDirtyState()
    }

    func didExitCurrentMode() {
        value?.didExitCurrentMode()
    }
}
