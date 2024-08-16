import Foundation
import UIKit

public protocol PDFDocumentSize {
    /// PPI of the document.
    var pointsPerInch: Double { get }
    /// The size of the document in inches.
    var inchDimensions: (width: Double, height: Double) { get }
    /// The size of the margins of the document, in inches.
    var inchMargins: (top: Double, left: Double, bottom: Double, right: Double) { get }
}

extension PDFDocumentSize {
    public var pointsPerInch: Double {
        72
    }

    /// The default margin size is 1 inch.
    public var inchMargins: (top: Double, left: Double, bottom: Double, right: Double) {
        (1, 1, 1, 1)
    }

    /// The size of the document in points, given the `pointsPerInch`.
    ///
    /// The default PPI of a PDF is 72.
    public func pointSize() -> (width: Double, height: Double) {
        let (width, height) = inchDimensions
        return (width * pointsPerInch, height * pointsPerInch)
    }

    public var pointMargins: UIEdgeInsets {
        UIEdgeInsets(
            top: inchMargins.top * pointsPerInch,
            left: inchMargins.left * pointsPerInch,
            bottom: inchMargins.bottom * pointsPerInch,
            right: inchMargins.right * pointsPerInch
        )
    }

    /// The size of the margins in pixels, given the `pointsPerInch`.

    /// The number of squares most appropriate for the size of the paper.
    ///
    /// This ensures that the squares sizing remains roughly constant, no matter the size of the paper.
    public var idealNumberOfHorizontalSquaresForPaperSize: UInt {
        let (width, _) = inchDimensions
        return UInt(width * 0.8)
    }
}

// MARK: - Sizes

public struct A3DocumentSize: PDFDocumentSize {
    public init() {}
    public var inchDimensions: (width: Double, height: Double) {
        (11.69, 16.54)
    }
}

public struct A4DocumentSize: PDFDocumentSize {
    public init() {}
    public var inchDimensions: (width: Double, height: Double) {
        (8.27, 11.69)
    }
}

public struct A5DocumentSize: PDFDocumentSize {
    public init() {}
    public var inchDimensions: (width: Double, height: Double) {
        (5.83, 8.27)
    }
}

public struct USLetterDocumentSize: PDFDocumentSize {
    public init() {}
    public var inchDimensions: (width: Double, height: Double) {
        (8.5, 11)
    }
}

public struct USLegalDocumentSize: PDFDocumentSize {
    public init() {}
    public var inchDimensions: (width: Double, height: Double) {
        (8.5, 14)
    }
}

public struct USTabloidDocumentSize: PDFDocumentSize {
    public init() {}
    public var inchDimensions: (width: Double, height: Double) {
        (11, 17)
    }
}
