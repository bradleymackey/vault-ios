import Combine
import Foundation
import OTPCore

public final class CodeTimerViewModel: ObservableObject {
    @Published public private(set) var timer: OTPTimerState?

    private var cancellable: AnyCancellable?
    private let clock: EpochClock

    public init(updater: some CodeTimerUpdater, clock: EpochClock) {
        self.clock = clock
        cancellable = updater.timerUpdatedPublisher()
            .sink { [weak self] state in
                self?.timer = state
            }
    }

    public var currentTime: Double {
        clock.currentTime
    }
}
