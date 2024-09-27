import Foundation
import FoundationExtensions

public enum CodeScanningState: Hashable, IdentifiableSelf {
    case disabled
    case scanning
    case success
    case invalidCodeScanned
    case codeDataError
}
