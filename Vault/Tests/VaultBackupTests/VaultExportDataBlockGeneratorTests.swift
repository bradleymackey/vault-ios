import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class VaultExportDataBlockGeneratorTests: XCTestCase {
    func test_makeDocument_createsExpectedContent() throws {
        let sut = VaultExportDataBlockGenerator(payload: .init(
            encryptedVault: .init(data: Data(), authentication: Data()),
            userDescription: "my desc",
            created: Date()
        ))

        let document = try sut.makeDocument(knownPageCount: 2)

        XCTAssertEqual(document.content.map(\.debugDescription), [
            "TITLE: Vault Export",
            "TITLE: my desc",
            "TITLE: To import this backup, scan all the QR codes below from all pages.",
            "IMAGES: count:1",
        ])
    }

    func test_makeDocument_splitsUserDescription() throws {
        let description = """
        This is my description
        It's very long

        I think everyone is lame



        nice
        """
        let sut = VaultExportDataBlockGenerator(payload: .init(
            encryptedVault: .init(data: Data(), authentication: Data()),
            userDescription: description,
            created: Date()
        ))

        let document = try sut.makeDocument(knownPageCount: 2)

        XCTAssertEqual(document.content.map(\.debugDescription), [
            "TITLE: Vault Export",
            "TITLE: This is my description",
            "TITLE: It\'s very long",
            "TITLE: I think everyone is lame",
            "TITLE: nice",
            "TITLE: To import this backup, scan all the QR codes below from all pages.",
            "IMAGES: count:1",
        ])
    }
}
