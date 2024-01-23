import CryptoDocumentExporter
import Foundation
import XCTest

final class PDFDocumentSizeTests: XCTestCase {
    func test_inchDimensions_usLetter() {
        let (width, height) = makeInches(USLetterDocumentSize())

        XCTAssertEqual(width, 8.5)
        XCTAssertEqual(height, 11)
    }

    func test_pointSize_usLetter() {
        let (width, height) = makeDefaultPointSize(USLetterDocumentSize())

        XCTAssertEqual(width, 612)
        XCTAssertEqual(height, 792)
    }

    func test_idealNumberOfHorizontalSquaresForPaperSize_usLetter() {
        let number = makeSquares(USLetterDocumentSize())

        XCTAssertEqual(number, 5)
    }

    // MARK: - Helpers

    private func makeInches(_ size: any PDFDocumentSize) -> (width: Double, height: Double) {
        size.inchDimensions
    }

    private func makeDefaultPointSize(_ size: any PDFDocumentSize) -> (width: Double, height: Double) {
        size.pointSize()
    }

    private func makeSquares(_ size: any PDFDocumentSize) -> Int {
        size.idealNumberOfHorizontalSquaresForPaperSize
    }
}
