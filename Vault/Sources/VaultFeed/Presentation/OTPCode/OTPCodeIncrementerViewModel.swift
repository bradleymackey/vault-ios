import Combine
import Foundation
import VaultCore

@MainActor
@Observable
public final class OTPCodeIncrementerViewModel {
    public private(set) var isButtonEnabled = true

    private let timer: any IntervalTimer
    private let codePublisher: HOTPCodePublisher
    private var counter: UInt64
    private var timerCancellable: AnyCancellable?

    public init(codePublisher: HOTPCodePublisher, timer: any IntervalTimer, initialCounter: UInt64) {
        self.timer = timer
        self.codePublisher = codePublisher
        counter = initialCounter
    }

    public func incrementCounter() {
        lockingWithButton {
            counter += 1
            codePublisher.set(counter: counter)
        }
    }

    public func lockingWithButton(operation: () -> Void) {
        guard isButtonEnabled else { return }
        isButtonEnabled = false

        operation()

        timerCancellable = timer.wait(for: 4)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isButtonEnabled = true
            }
    }
}
