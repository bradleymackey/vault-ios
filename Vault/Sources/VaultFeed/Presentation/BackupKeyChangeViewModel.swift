import CryptoEngine
import Foundation
import VaultBackup

@MainActor
@Observable
public final class BackupKeyChangeViewModel {
    public enum ExistingPasswordState: Equatable, Hashable {
        case loading
        case hasExistingPassword(BackupPassword)
        case noExistingPassword
        case errorFetching
    }

    public enum NewPasswordState: Equatable, Hashable {
        case neutral
        case creating
        case error
        case success
    }

    public var newlyEnteredPassword = ""
    public private(set) var existingPassword: ExistingPasswordState = .loading
    public private(set) var newPassword: NewPasswordState = .neutral
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public func loadInitialData() {
        do {
            if let password = try store.fetchPassword() {
                existingPassword = .hasExistingPassword(password)
            } else {
                existingPassword = .noExistingPassword
            }
        } catch {
            existingPassword = .errorFetching
        }
    }

    public func saveEnteredPassword() async {
        do {
            let enteredPassword = newlyEnteredPassword
            newPassword = .creating
            let keygenTask = Task.detached(priority: .background) {
                try BackupPassword.createEncryptionKey(text: enteredPassword)
            }
            let createdBackupPassword = try await keygenTask.value
            try store.set(password: createdBackupPassword)
            newPassword = .success
        } catch {
            newPassword = .error
        }
    }
}
