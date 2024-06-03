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

// MARK: - Strings

extension BackupViewModel {
    public struct Strings {
        fileprivate static var shared = Strings()
        private init() {}

        public let homeTitle = localized(key: "backupHome.title")
        public let backupPasswordCreateTitle = localized(key: "backupPasswordState.create.title")
        public let backupPasswordUpdateTitle = localized(key: "backupPasswordState.update.title")
        public let backupPasswordLoadingTitle = localized(key: "backupPasswordState.loading.title")
        public let backupPasswordErrorTitle = localized(key: "backupPasswordState.retrieveError.title")
        public let backupPasswordErrorDetail = localized(key: "backupPasswordState.retrieveError.detail")
    }

    public var strings: Strings {
        Strings.shared
    }
}
