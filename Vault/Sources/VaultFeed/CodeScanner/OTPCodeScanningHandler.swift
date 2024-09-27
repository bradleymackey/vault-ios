import Foundation
import VaultCore

/// Handles the scanning of OTP codes from a single QR code.
public final class OTPCodeScanningHandler: CodeScanningHandler {
    public init() {}

    public func decode(data: String) -> CodeScanningResult<OTPAuthCode> {
        do {
            guard let uri = OTPAuthURI(string: data) else {
                throw URLError(.badURL)
            }
            let code = try OTPAuthURIDecoder().decode(uri: uri)
            return .endScanning(.dataRetrieved(code))
        } catch {
            return .continueScanning(.invalidCode)
        }
    }
}
