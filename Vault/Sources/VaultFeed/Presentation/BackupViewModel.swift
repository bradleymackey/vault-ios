import Foundation

/// View model for the backups home view.
@MainActor
@Observable
public final class BackupViewModel {
    public enum PasswordState: Equatable, Hashable {
        case loading
        case hasExistingPassword
        case noExistingPassword
        case error
    }

    public private(set) var passwordState: PasswordState = .loading

    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore) {
        self.store = store
    }

    public func fetchContent() {
        fetchPasswordState()
    }
}

// MARK: - Password

extension BackupViewModel {
    private func fetchPasswordState() {
        do {
            let password = try store.fetchPassword()
            if password != nil {
                passwordState = .hasExistingPassword
            } else {
                passwordState = .noExistingPassword
            }
        } catch {
            passwordState = .error
        }
    }
}
