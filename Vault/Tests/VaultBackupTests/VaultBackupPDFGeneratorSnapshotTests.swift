import CryptoDocumentExporter
import Foundation
import TestHelpers
import VaultBackup
import XCTest

final class VaultExportSnapshotTests: XCTestCase {
    func test_makeDocument_createsExpectedContent() throws {
        let encryptedData = Data(repeating: 0x45, count: 10000)
        let authData = Data(repeating: 0x23, count: 200)
        let userDescription = Array(repeating: "User description.", count: 20).joined(separator: " ")
        let createdDate = Date(timeIntervalSince1970: 1_706_462_841)
        let payload = VaultExportPayload(
            encryptedVault: .init(data: encryptedData, authentication: authData),
            userDescription: userDescription,
            created: createdDate
        )

        let sut = VaultBackupPDFGenerator(
            size: A4DocumentSize(),
            documentTitle: "my document",
            applicationName: "my app",
            authorName: "my author"
        )
        let pdf = try sut.makePDF(payload: payload)

        assertSnapshot(of: pdf, as: .pdf())
    }
}
