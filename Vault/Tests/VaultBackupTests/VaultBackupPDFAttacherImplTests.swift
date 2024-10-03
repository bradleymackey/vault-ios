import Foundation
import PDFKit
import TestHelpers
import Testing
@testable import VaultBackup

struct VaultBackupPDFAttacherImplTests {
    @Test
    func attach_noPagesGeneratesError() throws {
        let sut = VaultBackupPDFAttacherImpl()
        var page = PDFDocument.noPages

        #expect(throws: (any Error).self) {
            try sut.attach(vault: anyEncryptedVault(), to: &page)
        }
    }

    @Test
    func attach_addsAttachmentOfEncryptedVault() throws {
        let sut = VaultBackupPDFAttacherImpl()
        var page = PDFDocument.onePage

        try sut.attach(vault: anyEncryptedVault(), to: &page)

        let pageOne = try #require(page.page(at: 0))
        let annotations = pageOne.annotations
        try #require(annotations.count == 1)

        let targetAnnotation = try #require(annotations.first)

        let expected =
            "vault.backup.encrypted-vault:ewogICJFTkNSWVBUSU9OX0FVVEhfVEFHIiA6ICIiLAogICJFTkNSWVBUSU9OX0RBVEEiIDogIiIsCiAgIkVOQ1JZUFRJT05fSVYiIDogIiIsCiAgIkVOQ1JZUFRJT05fVkVSU0lPTiIgOiAiMS4wLjAiLAogICJLRVlHRU5fU0FMVCIgOiAiIiwKICAiS0VZR0VOX1NJR05BVFVSRSIgOiAibXktc2lnbmF0dXJlIgp9"
        let retrieved = targetAnnotation.contents
        #expect(retrieved == expected)
    }
}

// MARK: - Helpers

extension VaultBackupPDFAttacherImplTests {
    private func anyEncryptedVault() -> EncryptedVault {
        EncryptedVault(
            data: Data(),
            authentication: Data(),
            encryptionIV: Data(),
            keygenSalt: Data(),
            keygenSignature: "my-signature"
        )
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
