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
    public let importContext: ImportContext
    /// The backup password the user already has on their device.
    /// If the imported backup was encrypted with this same password, we don't need to prompt the user.
    private let existingBackupPassword: BackupPassword?
    private let backupPDFDetatcher: any VaultBackupPDFDetatcher

    public init(
        importContext: ImportContext,
        existingBackupPassword: BackupPassword?,
        backupPDFDetatcher: any VaultBackupPDFDetatcher = VaultBackupPDFDetatcherImpl()
    ) {
        self.importContext = importContext
        self.existingBackupPassword = existingBackupPassword
        self.backupPDFDetatcher = backupPDFDetatcher
    }

    public func handleImport(result: Result<URL, any Error>) {
        switch result {
        case let .success(url):
            importPDF(fromURL: url)
        case let .failure(error):
            state = .error(PresentationError(
                userTitle: "File Error",
                userDescription: "There was an error with the file you selected. Please try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }

    struct InvalidURLError: Error {}

    private func importPDF(fromURL url: URL) {
        do {
            guard let pdf = PDFDocument(url: url) else {
                throw InvalidURLError()
            }
            let encryptedVault = try backupPDFDetatcher.detachEncryptedVault(fromPDF: pdf)
            // TODO: actually import the data
            state = .success
        } catch let error as LocalizedError {
            state = .error(.init(localizedError: error))
        } catch {
            state = .error(PresentationError(
                userTitle: "PDF Error",
                userDescription: "There was an error with the this PDF document. Please check the PDF, your internet, and try again.",
                debugDescription: "PDF unable to be created from url \(url). Likely malformed or no connection."
            ))
        }
    }
}
