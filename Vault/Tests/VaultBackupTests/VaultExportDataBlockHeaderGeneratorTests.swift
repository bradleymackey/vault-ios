import Foundation
import TestHelpers
import XCTest
@testable import VaultBackup

final class VaultExportDataBlockHeaderGeneratorTests: XCTestCase {
    func test_makeHeader_leftIsDate() {
        let date = Date(timeIntervalSince1970: 3_000_000)
        let sut = VaultExportDataBlockHeaderGenerator(dateCreated: date, totalNumberOfPages: 100)

        let header = sut.makeHeader(pageNumber: 1)

        XCTAssertEqual(header?.left, "Created 2/4/70, 6:20 PM")
    }

    func test_makeHeader_rightIsPageNumber() {
        let sut = VaultExportDataBlockHeaderGenerator(dateCreated: Date(), totalNumberOfPages: 500)

        let header = sut.makeHeader(pageNumber: 442)

        XCTAssertEqual(header?.right, "Page 442 of 500")
    }
}
