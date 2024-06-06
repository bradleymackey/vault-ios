import CoreGraphics
import CoreImage
import Foundation
import UIKit

/// Renders the provided data into a QR code.
public struct QRCodeImageRenderer: ImageDataRenderer {
    public init() {}

    public func makeImage(fromData data: Data, size: CGSize?) -> UIImage? {
        guard
            let qrCodePNGData = CIFilter.qrCode(data: data)?.outputImage?.asPNG(),
            let image = UIImage(data: qrCodePNGData)
        else {
            return nil
        }
        if let size {
            let resizer = UIImageResizer(mode: .noSmoothing)
            return resizer.resize(image: image, to: size)
        } else {
            return image
        }
    }
}

// MARK: - QR code generation

extension CIFilter {
    /// Create a filter to produce a QRCode from the provided data.
    ///
    /// - Returns: `nil` only if the filter cannot be loaded internally.
    fileprivate static func qrCode(data: Data) -> CIFilter? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        return filter
    }
}

extension CIImage {
    /// Convert this image into PNG data, in the `sRGB` color space.
    ///
    /// - Returns: `nil` if the image cannot be rendered.
    fileprivate func asPNG() -> Data? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        let context = CIContext()
        return context.pngRepresentation(of: self, format: .RGBA8, colorSpace: colorSpace)
    }
}
