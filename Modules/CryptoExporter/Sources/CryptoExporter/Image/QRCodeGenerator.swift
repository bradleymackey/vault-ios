import CoreGraphics
import CoreImage
import Foundation

public struct QRCodeGenerator {
    public init() {}

    /// Generates PNG data for a QR code containing the provided `data`.
    public func generatePNG(data: Data) -> Data? {
        CIFilter.qrCode(data: data)?.outputImage?.asPNG()
    }
}

private extension CIFilter {
    /// Create a filter to produce a QRCode from the provided data.
    ///
    /// - Returns: `nil` only if the filter cannot be loaded internally.
    static func qrCode(data: Data) -> CIFilter? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        return filter
    }
}

private extension CIImage {
    /// Convert this image into PNG data, in the `RBGA16` color space.
    ///
    /// - Returns: `nil` if the image cannot be rendered.
    func asPNG() -> Data? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        let context = CIContext()
        return context.pngRepresentation(of: self, format: .RGBA16, colorSpace: colorSpace)
    }
}
