import CryptoDocumentExporter
import Foundation
import TestHelpers
import VaultBackup
import XCTest

final class VaultBackupPDFGeneratorSnapshotTests: XCTestCase {
    func test_makeDocument_attachesMetadataDocumentAttributes() throws {
        let payload = makeTestingPayload(encryptedDataLength: 100)

        let sut = makeSUT()
        let pdf = try sut.makePDF(payload: payload)

        let attributes = pdf.documentAttributes as? [String: Any]
        XCTAssertEqual(attributes?["Creator"] as? String, "my app")
        XCTAssertEqual(attributes?["Author"] as? String, "my author")
        XCTAssertEqual(attributes?["Title"] as? String, "my document")
    }

    func test_makeDocument_attachesEncryptedPayloadAsDocumentAttribute() throws {
        let payload = makeTestingPayload(encryptedDataLength: 100)

        let sut = makeSUT()
        let pdf = try sut.makePDF(payload: payload)

        let expected =
            "ewogICJFTkNSWVBUSU9OX0FVVEhfVEFHIiA6ICJJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU1qSXlNakl5TWpJeU09IiwKICAiRU5DUllQVElPTl9EQVRBIiA6ICJSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSVVZGUlVWRlJVVkZSUT09IiwKICAiRU5DUllQVElPTl9JViIgOiAicjYrdnI2K3ZyNit2cjYrdnI2K3ZyNit2cjYrdnI2K3ZyNit2cjYrdiIsCiAgIkVOQ1JZUFRJT05fVkVSU0lPTiIgOiAiMS4wLjAiLAogICJLRVlHRU5fU0FMVCIgOiAiSWlJaUlpSWlJaUlpSWc9PSIsCiAgIktFWUdFTl9TSUdOQVRVUkUiIDogInNpZ25hdHVyZSIKfQ=="
        let retrieved = pdf.documentAttributes?["vault.backup.encrypted-vault"] as? String
        XCTAssertEqual(retrieved, expected)
    }

    func test_makeDocument_createsExpectedContent() throws {
        let payload = makeTestingPayload(encryptedDataLength: 10000)
        let sut = makeSUT()

        let pdf = try sut.makePDF(payload: payload)

        assertSnapshot(of: pdf, as: .pdf())
    }

    func test_makeDocument_sizesCorrectlyToOtherSize() throws {
        let payload = makeTestingPayload(encryptedDataLength: 10000)
        let sut = makeSUT(size: A5DocumentSize())

        let pdf = try sut.makePDF(payload: payload)

        assertSnapshot(of: pdf, as: .pdf())
    }
}

// MARK: - Helpers

extension VaultBackupPDFGeneratorSnapshotTests {
    private func makeSUT(size: some PDFDocumentSize = A4DocumentSize()) -> VaultBackupPDFGenerator {
        VaultBackupPDFGenerator(
            size: size,
            documentTitle: "my document",
            applicationName: "my app",
            authorName: "my author"
        )
    }

    private func makeTestingPayload(encryptedDataLength: Int) -> VaultExportPayload {
        let encryptedData = Data(repeating: 0x45, count: encryptedDataLength)
        let authData = Data(repeating: 0x23, count: 200)
        let ivData = Data(repeating: 0xAF, count: 30)
        let keySalt = Data(repeating: 0x22, count: 10)
        let userDescription = Array(repeating: "User description.", count: 20).joined(separator: " ")
        let createdDate = Date(timeIntervalSince1970: 1_706_462_841)
        return VaultExportPayload(
            encryptedVault: .init(
                data: encryptedData,
                authentication: authData,
                encryptionIV: ivData,
                keygenSalt: keySalt,
                keygenSignature: "signature"
            ),
            userDescription: userDescription,
            created: createdDate
        )
    }
}
