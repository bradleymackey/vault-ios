import Foundation

/// Represents the state of an accumulation when scanning codes.
public enum CodeScanningResult<Model> {
    /// Keep scanning for more codes.
    case continueScanning(ContinueScanningState)
    /// Scanning should end.
    case endScanning(EndScanningState)
}

extension CodeScanningResult {
    /// The message that should appear before continuing to scan.
    public enum ContinueScanningState: Equatable, Hashable {
        case success
        case invalidCode
        case ignore
    }

    public enum EndScanningState {
        case dataRetrieved(Model)
        /// The data is unable to be scanned in a way that we cannot recover from.
        /// We will be unable to retrieve data.
        case unrecoverableError
    }
}

extension CodeScanningResult.EndScanningState: Equatable where Model: Equatable {}
extension CodeScanningResult.EndScanningState: Hashable where Model: Hashable {}
extension CodeScanningResult: Equatable where Model: Equatable {}
extension CodeScanningResult: Hashable where Model: Hashable {}
