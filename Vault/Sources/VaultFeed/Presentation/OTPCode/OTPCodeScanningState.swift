import Foundation
import FoundationExtensions

public enum OTPCodeScanningState: Hashable, IdentifiableSelf {
    case disabled
    case scanning
    case success
    case invalidCodeScanned
}
