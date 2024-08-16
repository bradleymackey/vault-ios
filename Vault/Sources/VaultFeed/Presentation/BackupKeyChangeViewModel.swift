import CryptoEngine
import Foundation
import FoundationExtensions
import VaultBackup

@MainActor
@Observable
public final class BackupKeyChangeViewModel {
    public enum PermissionState: Equatable, Hashable {
        case loading
        case allowed
        case denied
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
    public internal(set) var permissionState: PermissionState = .loading
    public private(set) var newPassword: NewPasswordState = .initial
    private let encryptionKeyDeriver: ApplicationKeyDeriver<Bits256>
    private let authenticationService: DeviceAuthenticationService
    private let dataModel: VaultDataModel

    public init(
        dataModel: VaultDataModel,
        authenticationService: DeviceAuthenticationService,
        deriverFactory: some ApplicationKeyDeriverFactory
    ) {
        self.authenticationService = authenticationService
        self.dataModel = dataModel
        encryptionKeyDeriver = deriverFactory.makeApplicationKeyDeriver()
    }

    public var passwordConfirmMatches: Bool {
        newlyEnteredPassword == newlyEnteredPasswordConfirm
    }

    public var canGenerateNewPassword: Bool {
        !newPassword.isLoading && passwordConfirmMatches && !newlyEnteredPassword.isBlank && newlyEnteredPassword
            .isNotEmpty
    }

    public var encryptionKeyDeriverSignature: ApplicationKeyDeriver<Bits256>.Signature {
        encryptionKeyDeriver.signature
    }

    public func onAppear() async {
        do {
            try await authenticationService
                .validateAuthentication(reason: "Authenticate to change the backup password.")
            permissionState = .allowed
        } catch {
            permissionState = .denied
        }
    }

    public func didDisappear() {
        permissionState = .loading
    }

    private struct PasswordConfirmError: Error {}

    public func saveEnteredPassword() async {
        do {
            guard newlyEnteredPassword == newlyEnteredPasswordConfirm else {
                throw PasswordConfirmError()
            }

            newPassword = .creating
            let createdBackupPassword = try await computeNewKey(password: newlyEnteredPassword)
            try dataModel.store(backupPassword: createdBackupPassword)
            newPassword = .success
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

    public func loadExistingPassword() async {
        await dataModel.loadBackupPassword()
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
