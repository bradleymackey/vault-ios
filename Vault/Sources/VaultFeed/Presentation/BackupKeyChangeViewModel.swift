import CryptoEngine
import Foundation
import VaultBackup

@MainActor
@Observable
final class BackupKeyChangeViewModel {
    enum ExistingPasswordState: Equatable, Hashable {
        case loading
        case hasExistingPassword(BackupPassword)
        case noExistingPassword
    }

    private(set) var existingPassword: ExistingPasswordState = .loading
    private let store: any BackupPasswordStore

    init(store: any BackupPasswordStore) {
        self.store = store
    }

    func loadInitialData() {
        if let password = store.password {
            existingPassword = .hasExistingPassword(password)
        } else {
            existingPassword = .noExistingPassword
        }
    }
}
