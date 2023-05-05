import Combine
import Foundation
import OTPCore

public final class CodeTimerViewModel<Updater: CodeTimerUpdater>: ObservableObject {
    @Published public private(set) var timer: OTPTimerState?

    private let updater: Updater
    private var cancellable: AnyCancellable?
    private let clock: EpochClock

    public init(updater: Updater, clock: EpochClock) {
        self.clock = clock
        self.updater = updater
        cancellable = updater.timerUpdatedPublisher()
            .sink { [weak self] state in
                self?.timer = state
            }
    }

    public var currentTime: Double {
        clock.currentTime
    }
}
