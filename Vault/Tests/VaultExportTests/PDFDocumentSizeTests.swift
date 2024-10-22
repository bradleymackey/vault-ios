import Foundation
import Testing
import VaultExport

struct PDFDocumentSizeTests {
    @Test
    func inchDimensions_usLetter() {
        let (width, height) = makeInches(USLetterDocumentSize())

        #expect(width == 8.5)
        #expect(height == 11)
    }

    @Test
    func pointSize_isCorrect() {
        let (width, height) = makeDefaultPointSize(USLetterDocumentSize())

        #expect(width == 612)
        #expect(height == 792)
    }

    @Test
    func idealNumberOfHorizontalSquaresForPaperSize_isCorrect() {
        let number = makeSquares(USLetterDocumentSize())

        #expect(number == 6)
    }

    @Test
    func inchMargins_isStandardForUSLetter() {
        let margins = USLetterDocumentSize().inchMargins

        #expect(margins.top == 1)
        #expect(margins.left == 1)
        #expect(margins.bottom == 1)
        #expect(margins.right == 1)
    }

    @Test
    func pointMargins_isCorrect() {
        let margins = USLetterDocumentSize().pointMargins

        #expect(margins.top == 72)
        #expect(margins.left == 72)
        #expect(margins.bottom == 72)
        #expect(margins.right == 72)
    }

    @Test(arguments: [
        (USLetterDocumentSize(), 0.773),
        (A4DocumentSize(), 0.707),
        (A3DocumentSize(), 0.707),
    ] as [(any PDFDocumentSize, Double)])
    func aspectRatio_isCorrect(size: any PDFDocumentSize, expectedRatio: Double) {
        let aspectRatio = size.aspectRatio
        #expect(aspectRatio.isAlmostEqual(to: expectedRatio, tolerance: 0.001))
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
