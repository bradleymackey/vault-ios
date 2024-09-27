import Foundation
import FoundationExtensions

public enum CodeScanningState: Hashable, IdentifiableSelf {
    case disabled
    case scanning
    case success(Success)
    case failure(Failure)
}

extension CodeScanningState {
    public enum Success: Hashable {
        /// This is an intermediate success, we will continue after.
        case temporary
        /// The success is final.
        case complete
    }

    public enum Failure: Hashable {
        /// This is an intermediate failure, we will continue after.
        case temporary
        /// The failure is unrecoverable and we will not continue.
        case unrecoverable
    }
}
