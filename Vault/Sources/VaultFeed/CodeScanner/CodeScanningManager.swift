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
public final class CodeScanningManager<Handler: CodeScanningHandler> {
    public typealias Model = Handler.DecodedModel

    public private(set) var scanningState: CodeScanningState = .disabled
    private let scannedCodeSubject = PassthroughSubject<Model, Never>()
    private let intervalTimer: any IntervalTimer
    private let handler: Handler
    private var timerBag = Set<AnyCancellable>()

    public init(
        intervalTimer: any IntervalTimer,
        handler: Handler
    ) {
        self.intervalTimer = intervalTimer
        self.handler = handler
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
        let decoded = handler.decode(data: string)
        switch decoded {
        case let .continueScanning(state):
            switch state {
            case .ignore: break
            case .invalidCode:
                scanningState = .invalidCodeScanned
                intervalTimer.schedule(wait: 0.7) { @MainActor [weak self] in
                    self?.scanningState = .scanning
                }
            case .success:
                scanningState = .success
                intervalTimer.schedule(wait: 0.3) { @MainActor [weak self] in
                    self?.scanningState = .scanning
                }
            }
        case let .endScanning(state):
            switch state {
            case let .dataRetrieved(model):
                scanningState = .success
                intervalTimer.schedule(wait: 0.5) { @MainActor [scannedCodeSubject] in
                    scannedCodeSubject.send(model)
                }
            case .unrecoverableError:
                scanningState = .codeDataError
            }
        }
    }
}
