import Combine
import Foundation
import VaultCore

@MainActor
@Observable
public final class OTPCodeIncrementerViewModel {
    public private(set) var isButtonEnabled = true

    private let id: Identifier<VaultItem>
    private let timer: any IntervalTimer
    private let codePublisher: HOTPCodePublisher
    private var counter: UInt64
    private let incrementerStore: any VaultStoreHOTPIncrementer
    private var timerCancellable: AnyCancellable?

    public init(
        id: Identifier<VaultItem>,
        codePublisher: HOTPCodePublisher,
        timer: any IntervalTimer,
        initialCounter: UInt64,
        incrementerStore: any VaultStoreHOTPIncrementer
    ) {
        self.id = id
        self.timer = timer
        self.codePublisher = codePublisher
        counter = initialCounter
        self.incrementerStore = incrementerStore
    }

    public func incrementCounter() async throws {
        try await lockingWithButton {
            try await incrementerStore.incrementCounter(id: id)
            counter += 1
            codePublisher.set(counter: counter)
        }
    }

    private func lockingWithButton(operation: () async throws -> Void) async throws {
        guard isButtonEnabled else { return }
        isButtonEnabled = false

        try await operation()

        timerCancellable = timer.wait(for: 4)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isButtonEnabled = true
            }
    }
}
