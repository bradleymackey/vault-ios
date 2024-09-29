import Foundation
import VaultExport
import XCTest

final class PDFDocumentSizeTests: XCTestCase {
    func test_inchDimensions_usLetter() {
        let (width, height) = makeInches(USLetterDocumentSize())

        XCTAssertEqual(width, 8.5)
        XCTAssertEqual(height, 11)
    }

    func test_pointSize_isCorrect() {
        let (width, height) = makeDefaultPointSize(USLetterDocumentSize())

        XCTAssertEqual(width, 612)
        XCTAssertEqual(height, 792)
    }

    func test_idealNumberOfHorizontalSquaresForPaperSize_isCorrect() {
        let number = makeSquares(USLetterDocumentSize())

        XCTAssertEqual(number, 6)
    }

    func test_inchMargins_isStandardForUSLetter() {
        let margins = USLetterDocumentSize().inchMargins

        XCTAssertEqual(margins.top, 1)
        XCTAssertEqual(margins.left, 1)
        XCTAssertEqual(margins.bottom, 1)
        XCTAssertEqual(margins.right, 1)
    }

    func test_pointMargins_isCorrect() {
        let margins = USLetterDocumentSize().pointMargins

        XCTAssertEqual(margins.top, 72)
        XCTAssertEqual(margins.left, 72)
        XCTAssertEqual(margins.bottom, 72)
        XCTAssertEqual(margins.right, 72)
    }

    // MARK: - Helpers

    private func makeInches(_ size: any PDFDocumentSize) -> (width: Double, height: Double) {
        size.inchDimensions
    }

    private func makeDefaultPointSize(_ size: any PDFDocumentSize) -> (width: Double, height: Double) {
        size.pointSize()
    }

    private func makeSquares(_ size: any PDFDocumentSize) -> UInt {
        size.idealNumberOfHorizontalSquaresForPaperSize
    }
}
