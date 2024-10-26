import Foundation

/// Decides how scanned data from a code should be decoded.
///
/// This takes raw data from a QR code or similar and decodes it into a `DecodedModel`.
/// This should maintain it's own state so can build results from multiple pieces of data, so it can eventually
/// return a `DecodedModel` and, in the meantime, it can return partial results to the caller, indicating more data
/// is needed.
public protocol CodeScanningHandler<DecodedModel> {
    associatedtype Simulated: SimulatedCodeScanningHandler where Simulated.DecodedModel == DecodedModel
    associatedtype DecodedModel
    /// Decode data from the QR code to a model type.
    func decode(data: String) -> CodeScanningResult<DecodedModel>
    /// Creates a handler that can decode simulated results.
    func makeSimulatedHandler() -> Simulated
}

/// A simulated handler for code scanning.
///
/// This is used during testing/development when the camera is not available and we want to directly inject results
/// on the iOS Simulator, for example. Exact responses can be provided without needing to correctly construct mock
/// QR codes, which is a lot of work. Just define exactly what you want the result of a decoded QR code to be, and
/// return it in the form of a code scanning result.
///
/// @mockable(typealias: DecodedModel = String)
public protocol SimulatedCodeScanningHandler<DecodedModel> {
    associatedtype DecodedModel
    func decodeSimulated() -> CodeScanningResult<DecodedModel>
}

// MARK: - Mocks

public final class CodeScanningHandlerMock: CodeScanningHandler {
    public init() {}

    public typealias Simulated = SimulatedCodeScanningHandlerMock
    public typealias DecodedModel = String

    public private(set) var decodeCallCount = 0
    public var decodeArgValues = [String]()
    public var decodeHandler: ((String) -> (CodeScanningResult<DecodedModel>))?
    public func decode(data: String) -> CodeScanningResult<DecodedModel> {
        decodeCallCount += 1
        decodeArgValues.append(data)
        if let decodeHandler {
            return decodeHandler(data)
        }
        fatalError("decodeHandler returns can't have a default value thus its handler must be set")
    }

    public private(set) var makeSimulatedHandlerCallCount = 0
    public var makeSimulatedHandlerHandler: (() -> (Simulated))?
    public func makeSimulatedHandler() -> Simulated {
        makeSimulatedHandlerCallCount += 1
        if let makeSimulatedHandlerHandler {
            return makeSimulatedHandlerHandler()
        }
        return SimulatedCodeScanningHandlerMock()
    }
}
