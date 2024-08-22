import CryptoDocumentExporter
import CryptoEngine
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

    public enum Size: Equatable, IdentifiableSelf, CaseIterable, Codable {
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

    private static let pdfSizeKey = Key<Size>("vault.pdf.default-size")
    private static let userHintKey = Key<String>("vault.pdf.user-hint")
    private static let defaultUserHint =
        "This is my description, which is visible in plain text on the vault backup. You can use the Vault app to import this data if you lose access to this data."

    public private(set) var state: State = .idle
    public var size: Size = .a4
    public var authorName: String = "Vault"
    public var userHint: String = ""
    public var userDescriptionEncrypted: String = "You can use the Vault app to import this backup."
    public var createdDocument: PDFDocument?

    private let backupPassword: BackupPassword
    private let dataModel: VaultDataModel
    private let clock: EpochClock
    private let backupEventLogger: any BackupEventLogger
    private let defaults: Defaults

    public init(
        backupPassword: BackupPassword,
        dataModel: VaultDataModel,
        clock: EpochClock,
        backupEventLogger: any BackupEventLogger,
        defaults: Defaults
    ) {
        self.backupPassword = backupPassword
        self.dataModel = dataModel
        self.clock = clock
        self.backupEventLogger = backupEventLogger
        self.defaults = defaults

        size = defaults.get(for: Self.pdfSizeKey) ?? .a4
        userHint = defaults.get(for: Self.userHintKey) ?? Self.defaultUserHint
    }

    public func createPDF() async {
        do {
            state = .loading
            let payload = try await dataModel.makeExport(userDescription: userDescriptionEncrypted)
            createdDocument = try await makeBackupPDFDocument(payload: payload)
            let hash = try Hasher().sha256(value: payload)

            try? defaults.set(size, for: Self.pdfSizeKey)
            try? defaults.set(userHint, for: Self.userHintKey)

            backupEventLogger.exportedToPDF(date: clock.currentDate, hash: hash)
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
    private func makeBackupPDFDocument(payload: VaultApplicationPayload) async throws -> PDFDocument {
        let pdfCreator = VaultBackupPDFGenerator(
            size: size.documentSize,
            documentTitle: "Backup",
            applicationName: "Vault",
            authorName: authorName
        )
        let backupExporter = BackupExporter(clock: clock, backupPassword: backupPassword)
        let encryptedVault = try backupExporter.createEncryptedBackup(payload: payload)
        let exportPayload = VaultExportPayload(
            encryptedVault: encryptedVault,
            userDescription: userHint,
            created: clock.currentDate
        )
        return try pdfCreator.makePDF(payload: exportPayload)
    }
}
