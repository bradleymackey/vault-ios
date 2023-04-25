import Foundation

public enum PDFDocumentSize {
    case a2
    case a3
    case a4
    case a5
    case a6
    case usLetter
    case usLegal
    case usTabloid

    /// The size of the document in inches.
    public var inchDimensions: (width: Double, height: Double) {
        switch self {
        case .a2: return (16.54, 23.39)
        case .a3: return (11.69, 16.54)
        case .a4: return (8.27, 11.69)
        case .a5: return (5.83, 8.27)
        case .a6: return (4.13, 5.83)
        case .usLetter: return (8.5, 11)
        case .usLegal: return (8.5, 14)
        case .usTabloid: return (11, 17)
        }
    }

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
