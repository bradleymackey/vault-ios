import Combine
import Foundation
import VaultCore

/// Encapsultes view-level code scanning logic and error states.
/// The current state of the scanner is `scanningState`.
/// The scanned code is broadcast at `navigateToScannedCodePublisher`.
@MainActor
@Observable
public final class OTPCodeScanner {
    public private(set) var scanningState: OTPCodeScanningState = .disabled
    private let scannedCodeSubject = PassthroughSubject<OTPAuthCode, Never>()

    private let intervalTimer: any IntervalTimer
    private var timerBag = Set<AnyCancellable>()

    public init(intervalTimer: any IntervalTimer) {
        self.intervalTimer = intervalTimer
    }

    public func startScanning() {
        scanningState = .scanning
    }

    public func disable() {
        scanningState = .disabled
    }

    public func navigateToScannedCodePublisher() -> AnyPublisher<OTPAuthCode, Never> {
        scannedCodeSubject.eraseToAnyPublisher()
    }

    struct CodeFormatError: Error {}

    public func scan(text string: String) {
        do {
            guard let uri = OTPAuthURI(string: string) else {
                throw CodeFormatError()
            }
            let decoder = OTPAuthURIDecoder()
            let decoded = try decoder.decode(uri: uri)
            scanningState = .success
            intervalTimer.wait(for: 0.5).sink { [scannedCodeSubject] in
                scannedCodeSubject.send(decoded)
            }.store(in: &timerBag)
        } catch {
            scanningState = .invalidCodeScanned
            intervalTimer.wait(for: 1).sink { [weak self] in
                self?.scanningState = .scanning
            }.store(in: &timerBag)
        }
    }
}
