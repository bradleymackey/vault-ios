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
    }

    public enum ImportContext: Equatable {
        case toEmptyVault
        case merge
        case override
    }

    public private(set) var state: ImportState = .idle
    public let importContext: ImportContext

    public init(importContext: ImportContext) {
        self.importContext = importContext
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

    private func importPDF(fromURL url: URL) {
        do {
            let extracted = try extractEncryptedData(pdfURL: url)
            state = .success
        } catch let error as ExtractionError {
            state = .error(error.presentationError)
        } catch {
            state = .error(.init(
                userTitle: "Import Error",
                userDescription: "Unable to import document",
                debugDescription: error.localizedDescription
            ))
        }
    }
}

extension BackupImportFlowViewModel {
    private enum ExtractionError: Error {
        case unableToLoad(URL)
        case missingData
        case noPages
        case noAnnotations
        case malformedBase64Data

        var presentationError: PresentationError {
            switch self {
            case let .unableToLoad(url):
                PresentationError(
                    userTitle: "PDF Error",
                    userDescription: "There was an error with the this PDF document. Please check the PDF, your internet, and try again.",
                    debugDescription: "PDF unable to be created from url \(url). Likely malformed or no connection."
                )
            case .missingData, .noPages, .noAnnotations:
                PresentationError(
                    userTitle: "Not a Vault Export",
                    userDescription: "This is not a vault export or the data has been modified. Please scan the QR codes manually.",
                    debugDescription: "Missing data in document needed for extraction."
                )
            case .malformedBase64Data:
                PresentationError(
                    userTitle: "Can't Extract Data Automatically",
                    userDescription: "We couldn't read this document automatically. Please scan the QR codes manually.",
                    debugDescription: "Data is malformed for decoding."
                )
            }
        }
    }

    /// Extracts the `EncryptedVault` from the PDF using the data stored in the `documentAttributes`
    private func extractEncryptedData(pdfURL: URL) throws -> EncryptedVault {
        guard let pdf = PDFDocument(url: pdfURL) else {
            throw ExtractionError.unableToLoad(pdfURL)
        }
        guard let firstPage = pdf.page(at: 0) else {
            throw ExtractionError.noPages
        }
        guard let annotation = firstPage.annotations
            .first(where: { $0.contents?.starts(with: VaultIdentifiers.Backup.encryptedVaultData) == true })
        else {
            throw ExtractionError.noAnnotations
        }
        guard let contents = annotation.contents else {
            throw ExtractionError.noAnnotations
        }
        guard let encodedString = contents.split(separator: ":")[safeIndex: 1] else {
            throw ExtractionError.missingData
        }
        guard let data = Data(base64Encoded: String(encodedString)) else {
            throw ExtractionError.malformedBase64Data
        }
        return try EncryptedVaultCoder().decode(vaultData: data)
    }
}
