import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct CodeTimerHorizontalBarView<Updater: CodeTimerUpdater>: View {
    @ObservedObject public var viewModel: CodeTimerViewModel<Updater>

    private var color: Color
    @State private var currentFractionCompleted = 0.0

    init(viewModel: CodeTimerViewModel<Updater>, color: Color = .blue) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.color = color
    }

    public var body: some View {
        HorizontalTimerProgressBarView(
            initialFractionCompleted: 0,
            startSignaller: viewModel.timerPublisher(currentTime: { viewModel.currentTime }),
            direction: .drains,
            color: color
        )
    }
}

extension CodeTimerViewModel {
    /// Maps timer state updates to events that can be rendered by the progress bar.
    func timerPublisher(currentTime: @escaping () -> Double)
        -> AnyPublisher<HorizontalTimerProgressBarView.Progress, Never>
    {
        $timer.map { state in
            guard let state else { return .freeze(fraction: 1) }
            let time = currentTime()
            let completed = state.fractionCompleted(at: time)
            let remainingTime = state.remainingTime(at: time)
            return .startAnimating(startFraction: completed, duration: remainingTime)
        }
        .eraseToAnyPublisher()
    }
}

struct CodeTimerHorizontalBarView_Previews: PreviewProvider {
    static var previews: some View {
        CodeTimerHorizontalBarView<MockCodeTimerUpdater>(viewModel: viewModel(clock: clock))
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
            .onAppear {
                updater.subject.send(OTPTimerState(startTime: 15, endTime: 60))
            }
    }

    // MARK: - Helpers

    static func viewModel(clock: EpochClock) -> CodeTimerViewModel<MockCodeTimerUpdater> {
        CodeTimerViewModel(updater: updater, clock: clock)
    }

    private static let updater: MockCodeTimerUpdater = .init()

    static let clock = EpochClock { 40 }
}
