import Foundation

public enum PDFDocumentSize {
    case usLetter

    /// The size of the document in inches.
    public var inchDimensions: (width: Double, height: Double) {
        switch self {
        case .usLetter:
            return (8.5, 11)
        }
    }

    /// The size of the document in points, given the `pointsPerInch`.
    ///
    /// The default PPI of a PDF is 72.
    public func pointSize(pointsPerInch: Double = 72) -> (width: Double, height: Double) {
        let (width, height) = inchDimensions
        return (width * pointsPerInch, height * pointsPerInch)
    }
}
