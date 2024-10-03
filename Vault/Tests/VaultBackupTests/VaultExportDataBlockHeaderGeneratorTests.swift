import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct VaultExportDataBlockHeaderGeneratorTests {
    @Test
    func makeHeader_leftIsDate() {
        let date = Date(timeIntervalSince1970: 3_000_000)
        let sut = VaultExportDataBlockHeaderGenerator(dateCreated: date, totalNumberOfPages: 100)

        let header = sut.makeHeader(pageNumber: 1)

        #expect(header?.left == "Created 2/4/70, 5:20 PM")
    }

    @Test
    func makeHeader_rightIsPageNumber() {
        let sut = VaultExportDataBlockHeaderGenerator(dateCreated: Date(), totalNumberOfPages: 500)

        let header = sut.makeHeader(pageNumber: 442)

        #expect(header?.right == "Page 442 of 500")
    }
}
