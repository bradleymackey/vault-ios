import Foundation
import PDFKit
import VaultBackup
import VaultCore

@MainActor
@Observable
public final class BackupImportFlowViewModel {
    public enum PayloadState: Equatable {
        case none
        case needsPasswordEntry(EncryptedVault)
        case error(PresentationError)
        /// We need the UUID so each `ready` state is unique in terms of equality.
        case ready(VaultApplicationPayload, UUID)

        var isError: Bool {
            switch self {
            case .error: true
            case .none, .ready, .needsPasswordEntry: false
            }
        }
    }

    public enum ImportState: Equatable {
        case notStarted
        case error(PresentationError)
        case success

        public var isFinished: Bool {
            switch self {
            case .success: true
            default: false
            }
        }
    }

    public private(set) var importState: ImportState = .notStarted

    public private(set) var payloadState: PayloadState = .none
    public private(set) var isImporting: Bool = false
    public let importContext: BackupImportContext

    private let dataModel: VaultDataModel
    /// The backup password the user already has on their device.
    /// If the imported backup was encrypted with this same password, we don't need to prompt the user.
    private let existingBackupPassword: DerivedEncryptionKey?
    private let encryptedVaultDecoder: any EncryptedVaultDecoder
    private let backupPDFDetatcher: any VaultBackupPDFDetatcher
    private var importPDFTask: Task<Void, any Error>?

    public init(
        importContext: BackupImportContext,
        dataModel: VaultDataModel,
        existingBackupPassword: DerivedEncryptionKey?,
        encryptedVaultDecoder: any EncryptedVaultDecoder,
        backupPDFDetatcher: any VaultBackupPDFDetatcher = VaultBackupPDFDetatcherImpl()
    ) {
        self.importContext = importContext
        self.dataModel = dataModel
        self.existingBackupPassword = existingBackupPassword
        self.encryptedVaultDecoder = encryptedVaultDecoder
        self.backupPDFDetatcher = backupPDFDetatcher
    }

    public func handleImport(result: Result<Data, any Error>) async {
        importState = .notStarted
        switch result {
        case let .success(data):
            await importPDF(data: data)
        case let .failure(error):
            payloadState = .error(PresentationError(
                userTitle: "File Error",
                userDescription: "There was an error with the file you selected. Please try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }

    struct InvalidURLError: Error {}
    enum PasswordError: Error, LocalizedError {
        case noPassword

        var errorDescription: String? {
            switch self {
            case .noPassword: "No password"
            }
        }
    }

    private func importPDF(data: Data) async {
        do {
            isImporting = true
            defer { isImporting = false }
            guard let pdf = PDFDocument(data: data) else {
                throw InvalidURLError()
            }

            let encryptedVault = try backupPDFDetatcher.detachEncryptedVault(fromPDF: pdf)
            let flowState = BackupImportFlowState(
                encryptedVault: encryptedVault,
                encryptedVaultDecoder: encryptedVaultDecoder
            )
            let action = flowState.passwordProvided(password: existingBackupPassword)
            switch action {
            case .promptForDifferentPassword:
                payloadState = .needsPasswordEntry(encryptedVault)
            case let .backupDataError(error):
                throw error
            case let .readyToImport(applicationPayload):
                payloadState = .ready(applicationPayload, UUID())
            }
        } catch let error as LocalizedError {
            payloadState = .error(.init(localizedError: error))
        } catch {
            payloadState = .error(PresentationError(
                userTitle: "PDF Error",
                userDescription: "There was an error with the this PDF document. Please check the PDF, your internet, and try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }

    public func handleVaultDecoded(payload: VaultApplicationPayload) {
        payloadState = .ready(payload, UUID())
    }

    public func importPayload(payload: VaultApplicationPayload) async {
        do {
            switch importContext {
            case .toEmptyVault, .merge:
                try await dataModel.importMerge(payload: payload)
            case .override:
                try await dataModel.importOverride(payload: payload)
            }
            importState = .success
        } catch let error as LocalizedError {
            importState = .error(.init(localizedError: error))
        } catch {
            importState = .error(PresentationError(
                userTitle: "Import Error",
                userDescription: "There was an error importing the data to your vault. Please try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }
}
