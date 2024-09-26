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
public final class CodeScanningManager<Model> {
    public private(set) var scanningState: CodeScanningState = .disabled
    public let configuration: Configuration
    private let scannedCodeSubject = PassthroughSubject<Model, Never>()
    private let intervalTimer: any IntervalTimer
    private let mapper: (String) throws -> Model
    private var timerBag = Set<AnyCancellable>()

    public init(
        configuration: Configuration,
        intervalTimer: any IntervalTimer,
        mapper: @escaping (String) throws -> Model
    ) {
        self.configuration = configuration
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
            intervalTimer.schedule(wait: configuration.successDelay) { @MainActor [scannedCodeSubject] in
                scannedCodeSubject.send(decoded)
            }
        } catch {
            scanningState = .invalidCodeScanned
            intervalTimer.schedule(wait: configuration.errorDelay) { @MainActor [weak self] in
                self?.scanningState = .scanning
            }
        }
    }
}

extension CodeScanningManager {
    public struct Configuration {
        /// How long the error UI is shown for before we start scanning again.
        public var errorDelay: TimeInterval
        /// How long the success UI is shown for before we show the success UI.
        public var successDelay: TimeInterval

        public static var slowerNotices: Configuration {
            Configuration(errorDelay: 1, successDelay: 0.5)
        }

        public static var quickNotices: Configuration {
            Configuration(errorDelay: 1, successDelay: 0.3)
        }
    }
}
