import Foundation

public protocol PDFDocumentSize {
    /// The size of the document in inches.
    var inchDimensions: (width: Double, height: Double) { get }
}

extension PDFDocumentSize {
    /// The size of the document in points, given the `pointsPerInch`.
    ///
    /// The default PPI of a PDF is 72.
    public func pointSize(pointsPerInch: Double = 72) -> (width: Double, height: Double) {
        let (width, height) = inchDimensions
        return (width * pointsPerInch, height * pointsPerInch)
    }

    /// The number of squares most appropriate for the size of the paper.
    ///
    /// This ensures that the squares sizing remains roughly constant, no matter the size of the paper.
    public var idealNumberOfHorizontalSquaresForPaperSize: Int {
        let (width, _) = inchDimensions
        return Int(width / 1.6)
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
