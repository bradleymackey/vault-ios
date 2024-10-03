import Foundation
import TestHelpers
import Testing
@testable import VaultBackup

struct VaultExportDataBlockHeaderGeneratorTests {
    @Test(arguments: [
        (Date(timeIntervalSince1970: 3_000_000), "Created 2/4/70, 5:20 PM"),
        (Date(timeIntervalSince1970: 1_727_868_260), "Created 10/2/24, 11:24 AM"),
    ])
    func makeHeader_leftIsDate(date: Date, expected: String) {
        let sut = VaultExportDataBlockHeaderGenerator(dateCreated: date, totalNumberOfPages: 100)

        let header = sut.makeHeader(pageNumber: 1)

        #expect(header?.left == expected)
    }

    @Test(arguments: [
        (1, 1, "Page 1 of 1"),
        (1, 99, "Page 1 of 99"),
        (442, 500, "Page 442 of 500"),
        (999, 999, "Page 999 of 999"),
    ])
    func makeHeader_rightIsPageNumber(pageNumber: Int, totalPages: Int, expected: String) {
        let sut = VaultExportDataBlockHeaderGenerator(dateCreated: Date(), totalNumberOfPages: totalPages)

        let header = sut.makeHeader(pageNumber: pageNumber)

        #expect(header?.right == expected)
    }
}
