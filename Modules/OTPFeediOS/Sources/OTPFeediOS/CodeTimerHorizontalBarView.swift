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
        GeometryReader { proxy in
            HorizontalTimerProgressBarView(
                fractionCompleted: $currentFractionCompleted,
                color: color
            )
            .onReceive(viewModel.timerPublisher()) { progress in
                updateState(progress: progress)
            }
            .onAppear {
                viewModel.recalculateTimer()
            }
            .onChange(of: proxy.size) { _ in
                viewModel.recalculateTimer()
            }
        }
    }

    private func updateState(progress: CodeTimerProgress) {
        withAnimation(.linear(duration: 0.15)) {
            currentFractionCompleted = progress.initialFraction
        }
        if case let .startAnimating(_, duration) = progress {
            withAnimation(.linear(duration: duration)) {
                currentFractionCompleted = 0
            }
        }
    }
}

private enum CodeTimerProgress {
    case freeze(fraction: Double)
    case startAnimating(startFraction: Double, duration: Double)

    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .startAnimating(fraction, _):
            return fraction
        }
    }
}

private extension CodeTimerViewModel {
    /// Maps timer state updates to events that can be rendered by the progress bar.
    func timerPublisher() -> AnyPublisher<CodeTimerProgress, Never> {
        $timer.map { state in
            guard let state else { return .freeze(fraction: 1) }
            let time = self.currentTime
            let completed = state.fractionCompleted(at: time)
            let remainingTime = state.remainingTime(at: time)
            return .startAnimating(startFraction: 1 - completed, duration: remainingTime)
        }
        .receive(on: RunLoop.main)
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
