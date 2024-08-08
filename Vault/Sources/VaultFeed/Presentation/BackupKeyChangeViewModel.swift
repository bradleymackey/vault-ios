import CryptoEngine
import Foundation
import VaultBackup

@MainActor
@Observable
public final class BackupKeyChangeViewModel {
    public enum ExistingPasswordState: Equatable, Hashable {
        case loading
        case authenticationFailed
        case hasExistingPassword(BackupPassword)
        case noExistingPassword
        case errorFetching
    }

    public enum NewPasswordState: Equatable, Hashable {
        case initial
        case creating
        case keygenError
        case keygenCancelled
        case passwordConfirmError
        case success

        public var isLoading: Bool {
            switch self {
            case .initial, .keygenError, .keygenCancelled, .passwordConfirmError, .success: false
            case .creating: true
            }
        }
    }

    public var newlyEnteredPassword = ""
    public var newlyEnteredPasswordConfirm = ""
    public private(set) var existingPassword: ExistingPasswordState = .loading
    public private(set) var newPassword: NewPasswordState = .initial
    private let encryptionKeyDeriver: ApplicationKeyDeriver
    private let store: any BackupPasswordStore

    public init(store: any BackupPasswordStore, deriverFactory: some ApplicationKeyDeriverFactory) {
        self.store = store
        encryptionKeyDeriver = deriverFactory.makeApplicationKeyDeriver()
    }

    public var passwordConfirmMatches: Bool {
        newlyEnteredPassword == newlyEnteredPasswordConfirm
    }

    public var canGenerateNewPassword: Bool {
        !newPassword.isLoading && passwordConfirmMatches && !newlyEnteredPassword.isBlank && newlyEnteredPassword
            .isNotEmpty
    }

    public var encryptionKeyDeriverSignature: ApplicationKeyDeriver.Signature {
        encryptionKeyDeriver.signature
    }

    public func loadInitialData() {
        do {
            if let password = try store.fetchPassword() {
                existingPassword = .hasExistingPassword(password)
            } else {
                existingPassword = .noExistingPassword
            }
        } catch is DeviceAuthenticationFailure {
            existingPassword = .authenticationFailed
        } catch {
            existingPassword = .errorFetching
        }
    }

    public func didDisappear() {
        existingPassword = .loading
    }

    private struct PasswordConfirmError: Error {}

    public func saveEnteredPassword() async {
        do {
            guard newlyEnteredPassword == newlyEnteredPasswordConfirm else {
                throw PasswordConfirmError()
            }

            newPassword = .creating
            let createdBackupPassword = try await computeNewKey(password: newlyEnteredPassword)
            try store.set(password: createdBackupPassword)
            newPassword = .success
            existingPassword = .hasExistingPassword(createdBackupPassword)
            newlyEnteredPassword = ""
            newlyEnteredPasswordConfirm = ""
        } catch is PasswordConfirmError {
            newPassword = .passwordConfirmError
        } catch is CancellationError {
            newPassword = .keygenCancelled
        } catch {
            newPassword = .keygenError
        }
    }

    private nonisolated func computeNewKey(password: String) async throws -> BackupPassword {
        let deriver = encryptionKeyDeriver
        let generatedPassword = try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .utility).async {
                cont.resume(with: Result {
                    try BackupPassword.createEncryptionKey(deriver: deriver, password: password)
                })
            }
        }
        try Task.checkCancellation()
        return generatedPassword
    }
}
