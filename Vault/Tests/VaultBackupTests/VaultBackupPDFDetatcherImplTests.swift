import Foundation
import PDFKit
import TestHelpers
import VaultCore
import XCTest
@testable import VaultBackup

final class VaultBackupPDFDetatcherImplTests: XCTestCase {
    func test_detachEncryptedVault_decodesIfPresent() throws {
        let sut = makeSUT()
        let pdf = PDFDocument.onePage
        let annotation = try makeVaultAnnotation(vault: anyEncryptedVault())
        pdf.page(at: 0)?.addAnnotation(annotation)

        let result = try sut.detachEncryptedVault(fromPDF: pdf)

        XCTAssertEqual(result, anyEncryptedVault())
    }

    func test_detachEncryptedVault_noPagesThrowsError() throws {
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.detachEncryptedVault(fromPDF: .noPages))
    }

    func test_detachEncryptedVault_noAnnotationsThrowsError() throws {
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.detachEncryptedVault(fromPDF: .onePage))
    }

    func test_detachEncryptedVault_missingPayloadThrowsError() throws {
        let sut = makeSUT()
        let pdf = PDFDocument.onePage
        let annotation = makeEmptyAnnotation()
        pdf.page(at: 0)?.addAnnotation(annotation)

        XCTAssertThrowsError(try sut.detachEncryptedVault(fromPDF: pdf))
    }

    func test_detachEncryptedVault_invalidDataThrowsError() throws {
        let sut = makeSUT()
        let pdf = PDFDocument.onePage
        let annotation = makeInvalidDataAnnotation()
        pdf.page(at: 0)?.addAnnotation(annotation)

        XCTAssertThrowsError(try sut.detachEncryptedVault(fromPDF: pdf))
    }
}

// MARK: - Helpers

extension VaultBackupPDFDetatcherImplTests {
    private func makeSUT() -> VaultBackupPDFDetatcherImpl {
        .init()
    }

    private func anyEncryptedVault() -> EncryptedVault {
        EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: "my-signature"
        )
    }

    private func makeVaultAnnotation(vault: EncryptedVault) throws -> PDFAnnotation {
        let annotation = PDFAnnotation(
            bounds: CGRect(x: -100, y: -100, width: 100, height: 100),
            forType: .circle,
            withProperties: nil
        )
        let encoded = try makeEncodedVault(vault: vault)
        annotation.contents = "\(VaultIdentifiers.Backup.encryptedVaultData):" + encoded
        return annotation
    }

    private func makeEmptyAnnotation() -> PDFAnnotation {
        let annotation = PDFAnnotation(
            bounds: CGRect(x: -100, y: -100, width: 100, height: 100),
            forType: .circle,
            withProperties: nil
        )
        annotation.contents = "\(VaultIdentifiers.Backup.encryptedVaultData):"
        return annotation
    }

    private func makeInvalidDataAnnotation() -> PDFAnnotation {
        let annotation = PDFAnnotation(
            bounds: CGRect(x: -100, y: -100, width: 100, height: 100),
            forType: .circle,
            withProperties: nil
        )
        annotation.contents = "\(VaultIdentifiers.Backup.encryptedVaultData):AAAAA"
        return annotation
    }

    private func makeEncodedVault(vault: EncryptedVault) throws -> String {
        let coder = EncryptedVaultCoder()
        let encodedVault = try coder.encode(vault: vault)
        return encodedVault.base64EncodedString()
    }
}

extension PDFDocument {
    fileprivate static var noPages: PDFDocument {
        PDFDocument()
    }

    fileprivate static var onePage: PDFDocument {
        let renderer = UIGraphicsPDFRenderer()
        let data = renderer.pdfData { context in
            context.beginPage()
        }
        return PDFDocument(data: data)!
    }
}
