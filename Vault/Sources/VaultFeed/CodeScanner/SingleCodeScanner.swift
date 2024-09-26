import Combine
import Foundation
import VaultCore

/// Encapsultes view-level scanning logic and error states of a single code.
/// This encourages a single code to be scanned, allowing a custom `mapper` to
/// define either a successful scan, or a scanning error.
///
/// The current state of the scanner is `scanningState`.
/// The scanned model is broadcast at `itemScannedPublisher`.
@MainActor
@Observable
public final class SingleCodeScanner<Model> {
    public private(set) var scanningState: CodeScanningState = .disabled
    private let scannedCodeSubject = PassthroughSubject<Model, Never>()

    private let intervalTimer: any IntervalTimer
    private let mapper: (String) throws -> Model
    private var timerBag = Set<AnyCancellable>()

    public init(intervalTimer: any IntervalTimer, mapper: @escaping (String) throws -> Model) {
        self.intervalTimer = intervalTimer
        self.mapper = mapper
    }

    public func startScanning() {
        scanningState = .scanning
    }

    public func disable() {
        scanningState = .disabled
    }

    public func itemScannedPublisher() -> AnyPublisher<Model, Never> {
        scannedCodeSubject.eraseToAnyPublisher()
    }

    public func scan(text string: String) {
        do {
            let decoded = try mapper(string)
            scanningState = .success
            intervalTimer.schedule(wait: 0.5, tolerance: 0.5) { @MainActor [scannedCodeSubject] in
                scannedCodeSubject.send(decoded)
            }
        } catch {
            scanningState = .invalidCodeScanned
            intervalTimer.schedule(wait: 1, tolerance: 0.5) { @MainActor [weak self] in
                self?.scanningState = .scanning
            }
        }
    }
}
