import Foundation

/// Represents the state of an accumulation when scanning codes.
public enum CodeScanningResult<Model> {
    /// Keep scanning for more codes.
    case continueScanning
    /// The model was decoded.
    case completedScanning(Model)
}

extension CodeScanningResult: Equatable where Model: Equatable {}
extension CodeScanningResult: Hashable where Model: Hashable {}
