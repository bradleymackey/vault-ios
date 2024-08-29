import Foundation
import FoundationExtensions
import PDFKit
import VaultBackup

/// Controls the state and flow of logic during import operations.
struct BackupImportFlowState {
    /// Actions that should be taken given the current state.
    enum Action {
        case backupDataError(any Error)
        /// Decryption password was invalid, the user should try again with a different
        /// password.
        case promptForDifferentPassword
        case importAndMerge(VaultApplicationPayload)
        case importAndOverride(VaultApplicationPayload)
    }

    let importContext: BackupImportContext
    let encryptedVault: EncryptedVault

    init(importContext: BackupImportContext, encryptedVault: EncryptedVault) {
        self.importContext = importContext
        self.encryptedVault = encryptedVault
    }

    /// There was a password provided, handle the state.
    func passwordProvided(password: BackupPassword) -> Action {
        do {
            let backupImporter = BackupImporter(backupPassword: password)
            let applicationPayload = try backupImporter.importEncryptedBackup(encryptedVault: encryptedVault)
            switch importContext {
            case .toEmptyVault: return .importAndMerge(applicationPayload)
            case .merge: return .importAndMerge(applicationPayload)
            case .override: return .importAndOverride(applicationPayload)
            }
        } catch BackupImporter.ImportError.decryption {
            return .promptForDifferentPassword
        } catch {
            return .backupDataError(error)
        }
    }
}
