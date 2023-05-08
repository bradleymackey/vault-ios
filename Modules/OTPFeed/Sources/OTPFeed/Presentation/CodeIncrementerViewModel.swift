import Combine
import Foundation
import OTPCore

@MainActor
public final class CodeIncrementerViewModel<Timer: IntervalTimer>: ObservableObject {
    @Published public private(set) var isButtonEnabled = true

    private let timer: Timer
    private let hotpRenderer: HOTPCodeRenderer
    private var counter: UInt64
    private var timerCancellable: AnyCancellable?

    public init(hotpRenderer: HOTPCodeRenderer, timer: Timer, initialCounter: UInt64) {
        self.timer = timer
        self.hotpRenderer = hotpRenderer
        counter = initialCounter
        hotpRenderer.set(counter: initialCounter)
    }

    public func incrementCounter() {
        lockingWithButton {
            counter += 1
            hotpRenderer.set(counter: counter)
        }
    }

    public func lockingWithButton(operation _: () -> Void) {
        guard isButtonEnabled else { return }
        isButtonEnabled = false

        timerCancellable = timer.wait(for: 4)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isButtonEnabled = true
            }
    }
}
