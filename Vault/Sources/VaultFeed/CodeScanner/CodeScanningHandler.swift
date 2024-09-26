import Foundation

/// @mockable(typealias: DecodedModel = String)
public protocol CodeScanningHandler {
    associatedtype DecodedModel
    /// Decode data from the QR code to a model type.
    func decode(data: String) throws -> CodeScanningResult<DecodedModel>
}
