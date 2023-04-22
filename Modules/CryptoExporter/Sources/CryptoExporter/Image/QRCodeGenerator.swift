import CoreGraphics
import CoreImage
import Foundation

public struct QRCodeGenerator {
    public init() {}

    public func generatePNG(data: Data) -> Data? {
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            if let ciImage = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
                return context.pngRepresentation(of: ciImage, format: .RGBA16, colorSpace: colorSpace)
            }
        }
        return nil
    }
}
