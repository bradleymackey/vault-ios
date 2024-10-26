import Foundation

public protocol CodeScanningHandler<DecodedModel> {
    associatedtype Simulated: SimulatedCodeScanningHandler where Simulated.DecodedModel == DecodedModel
    associatedtype DecodedModel
    /// Decode data from the QR code to a model type.
    func decode(data: String) -> CodeScanningResult<DecodedModel>
    /// Creates a handler that can decode simulated results.
    func makeSimulatedHandler() -> Simulated
}

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
