import Combine
import Foundation
import OTPCore

public final class CodeTimerViewModel: ObservableObject {
    @Published public private(set) var timer: OTPTimerState?

    private var cancellable: AnyCancellable?

    public init(clock: some EpochClock, updater: some CodeTimerUpdater) {
        cancellable = updater.timerUpdatedPublisher()
            .sink { [weak self] state in
                self?.timer = state
                clock.tick()
            }
    }
}
