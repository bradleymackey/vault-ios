import CryptoExporter
import Foundation
import XCTest

final class PDFDocumentSizeTests: XCTestCase {
    func test_inchDimensions_usLetter() {
        let (width, height) = makeInches(.usLetter)

        XCTAssertEqual(width, 8.5)
        XCTAssertEqual(height, 11)
    }

    func test_pointSize_usLetter() {
        let (width, height) = makeDefaultPointSize(.usLetter)

        XCTAssertEqual(width, 612)
        XCTAssertEqual(height, 792)
    }

    func test_idealNumberOfHorizontalSquaresForPaperSize_usLetter() {
        let number = makeSquares(.usLetter)

        XCTAssertEqual(number, 5)
    }

    // MARK: - Helpers

    private func makeInches(_ size: PDFDocumentSize) -> (width: Double, height: Double) {
        size.inchDimensions
    }

    private func makeDefaultPointSize(_ size: PDFDocumentSize) -> (width: Double, height: Double) {
        size.pointSize()
    }

    private func makeSquares(_ size: PDFDocumentSize) -> Int {
        size.idealNumberOfHorizontalSquaresForPaperSize
    }
}
