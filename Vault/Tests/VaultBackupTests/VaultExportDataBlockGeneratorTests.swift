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
            "TITLE: The following data is encrypted and encoded as a series of QR codes. To import this backup, you should scan every single code in the Vault app. There should be 1 in total.",
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
            "TITLE: The following data is encrypted and encoded as a series of QR codes. To import this backup, you should scan every single code in the Vault app. There should be 1 in total.",
            "IMAGES: count:1",
        ])
    }
}
