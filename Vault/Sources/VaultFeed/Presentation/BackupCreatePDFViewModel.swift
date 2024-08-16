import CryptoDocumentExporter
import Foundation
import FoundationExtensions
import PDFKit
import VaultBackup
import VaultCore

@MainActor
@Observable
public final class BackupCreatePDFViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case error(PresentationError)
        case success

        public var isError: Bool {
            switch self {
            case .error: true
            default: false
            }
        }
    }

    public enum Size: IdentifiableSelf {
        case a3
        case a4
        case a5
        case usLetter
        case usLegal
        case usTabloid

        public var localizedTitle: String {
            switch self {
            case .a3: "A3"
            case .a4: "A4"
            case .a5: "A5"
            case .usLetter: "US Letter"
            case .usLegal: "US Legal"
            case .usTabloid: "US Tabloid"
            }
        }

        fileprivate var documentSize: any PDFDocumentSize {
            switch self {
            case .a3: A3DocumentSize()
            case .a4: A4DocumentSize()
            case .a5: A5DocumentSize()
            case .usLetter: USLetterDocumentSize()
            case .usLegal: USLegalDocumentSize()
            case .usTabloid: USTabloidDocumentSize()
            }
        }
    }

    public private(set) var state: State = .idle
    public private(set) var size: Size = .a4
    public var authorName: String = "User"
    public var userHint: String = "This is a backup of my Vault data."
    public var userDescriptionEncrypted: String = "I should use the Vault app to import this backup."
    public var createdDocument: PDFDocument?

    private let backupPassword: BackupPassword
    private let dataModel: VaultDataModel
    private let clock: EpochClock

    public init(backupPassword: BackupPassword, dataModel: VaultDataModel, clock: EpochClock) {
        self.backupPassword = backupPassword
        self.dataModel = dataModel
        self.clock = clock
    }

    public func createPDF() async {
        do {
            state = .loading
            createdDocument = try await makeBackupPDFDocument()
            state = .success
        } catch {
            state = .error(.init(
                userTitle: "PDF Error",
                userDescription: "Failed to create PDF. Please try again.",
                debugDescription: error.localizedDescription
            ))
        }
    }

    /// Exports and encrypts the full vault from storage, rendering to a PDF
    private func makeBackupPDFDocument() async throws -> PDFDocument {
        let pdfCreator = VaultBackupPDFGenerator(
            size: size.documentSize,
            documentTitle: "Backup",
            applicationName: "Vault",
            authorName: authorName
        )
        let applicationPayload = try await dataModel.makeExport(userDescription: userDescriptionEncrypted)
        let backupExporter = BackupExporter(clock: clock, backupPassword: backupPassword)
        let encryptedVault = try backupExporter.createEncryptedBackup(payload: applicationPayload)
        let exportPayload = VaultExportPayload(
            encryptedVault: encryptedVault,
            userDescription: userHint,
            created: clock.currentDate
        )
        return try pdfCreator.makePDF(payload: exportPayload)
    }
}
