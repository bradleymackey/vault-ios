import Combine
import Foundation

public final class CodeTimerViewModel: ObservableObject {
    @Published public private(set) var timer: OTPTimerState?

    private var cancellable: AnyCancellable?

    public init(updater: some CodeTimerUpdater) {
        cancellable = updater.timerUpdatedPublisher()
            .sink { [weak self] state in
                self?.timer = state
            }
    }
}
