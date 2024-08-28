import Foundation
import PDFKit
import VaultBackup
import VaultCore

@MainActor
@Observable
public final class BackupImportFlowViewModel {
    public enum ImportState: Equatable {
        case idle
        case error(PresentationError)
        case success

        var isError: Bool {
            switch self {
            case .error: true
            case .idle, .success: false
            }
        }
    }

    public enum ImportContext: Equatable {
        case toEmptyVault
        case merge
        case override
    }

    public private(set) var state: ImportState = .idle
    public private(set) var isImporting: Bool = false
    public let importContext: ImportContext

    private let dataModel: VaultDataModel
    /// The backup password the user already has on their device.
    /// If the imported backup was encrypted with this same password, we don't need to prompt the user.
    private let existingBackupPassword: BackupPassword?
    private let backupPDFDetatcher: any VaultBackupPDFDetatcher
    private var importPDFTask: Task<Void, any Error>?

    public init(
        importContext: ImportContext,
        dataModel: VaultDataModel,
        existingBackupPassword: BackupPassword?,
        backupPDFDetatcher: any VaultBackupPDFDetatcher = VaultBackupPDFDetatcherImpl()
    ) {
        self.importContext = importContext
        self.dataModel = dataModel
        self.existingBackupPassword = existingBackupPassword
        self.backupPDFDetatcher = backupPDFDetatcher
    }

    public func handleImport(result: Result<Data, any Error>) async {
        switch result {
        case let .success(data):
            await importPDF(data: data)
        case let .failure(error):
            state = .error(PresentationError(
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

            // TODO: handle case where imported vault was encrypted with different password, should prompt user for it
            guard let existingBackupPassword else { throw PasswordError.noPassword }
            let encryptedVault = try backupPDFDetatcher.detachEncryptedVault(fromPDF: pdf)
            let applicationPayload = try await extractPayload(
                password: existingBackupPassword,
                encryptedVault: encryptedVault
            )

            switch importContext {
            case .merge, .toEmptyVault:
                try await dataModel.importMerge(payload: applicationPayload)
            case .override:
                try await dataModel.importOverride(payload: applicationPayload)
            }

            state = .success
        } catch let error as LocalizedError {
            state = .error(.init(localizedError: error))
        } catch {
            state = .error(PresentationError(
                userTitle: "PDF Error",
                userDescription: "There was an error with the this PDF document. Please check the PDF, your internet, and try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }
}

// MARK: - Importing Vault

extension BackupImportFlowViewModel {
    private nonisolated func extractPayload(
        password: BackupPassword,
        encryptedVault: EncryptedVault
    ) async throws -> VaultApplicationPayload {
        let backupImporter = BackupImporter(backupPassword: password)
        return try backupImporter.importEncryptedBackup(encryptedVault: encryptedVault)
    }
}
