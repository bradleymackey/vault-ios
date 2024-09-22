import Foundation
import FoundationExtensions
import VaultBackup
import VaultKeygen

@MainActor
@Observable
public final class BackupKeyChangeViewModel {
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
    public internal(set) var permissionState: PermissionState = .undetermined
    public private(set) var newPassword: NewPasswordState = .initial
    private let encryptionKeyDeriver: VaultKeyDeriver
    private let authenticationService: DeviceAuthenticationService
    private let dataModel: VaultDataModel

    public init(
        dataModel: VaultDataModel,
        authenticationService: DeviceAuthenticationService,
        deriverFactory: some VaultKeyDeriverFactory
    ) {
        self.authenticationService = authenticationService
        self.dataModel = dataModel
        encryptionKeyDeriver = deriverFactory.makeVaultKeyDeriver()
    }

    public var passwordConfirmMatches: Bool {
        newlyEnteredPassword == newlyEnteredPasswordConfirm
    }

    public var canGenerateNewPassword: Bool {
        !newPassword.isLoading && passwordConfirmMatches && !newlyEnteredPassword.isBlank && newlyEnteredPassword
            .isNotEmpty
    }

    public var encryptionKeyDeriverSignature: VaultKeyDeriver.Signature {
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
        permissionState = .undetermined
    }

    private struct PasswordConfirmError: Error {}

    public func saveEnteredPassword() async {
        do {
            guard newlyEnteredPassword == newlyEnteredPasswordConfirm else {
                throw PasswordConfirmError()
            }

            newPassword = .creating
            let createdBackupPassword = try await computeNewKey(password: newlyEnteredPassword)
            try await dataModel.store(backupPassword: createdBackupPassword)
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

    private nonisolated func computeNewKey(password: String) async throws -> DerivedEncryptionKey {
        try await Task.continuation(priority: .background) {
            try self.encryptionKeyDeriver.createEncryptionKey(password: password)
        }
    }
}
