import Foundation
import PDFKit

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
    public private(set) var pdf: PDFDocument?
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
        if let pdf = PDFDocument(url: url) {
            self.pdf = pdf
            state = .success
        } else {
            state = .error(PresentationError(
                userTitle: "PDF Error",
                userDescription: "There was an error with the this PDF document. Please check the contents and try again.",
                debugDescription: "PDF unable to be created from url \(url). Likely malformed."
            ))
        }
    }
}
