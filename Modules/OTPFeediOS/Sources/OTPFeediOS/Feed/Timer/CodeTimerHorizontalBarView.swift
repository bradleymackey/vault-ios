import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct CodeTimerHorizontalBarView<Updater: CodeTimerUpdater>: View {
    var clock: EpochClock
    var updater: Updater
    var color: Color = .blue
    var backgroundColor: Color = .init(UIColor.systemGray2).opacity(0.3)

    @State private var currentFractionCompleted = 0.0
    @Environment(\.scenePhase) private var scenePhase

    public var body: some View {
        GeometryReader { proxy in
            HorizontalTimerProgressBarView(
                fractionCompleted: $currentFractionCompleted,
                color: color,
                backgroundColor: backgroundColor
            )
            .onChange(of: proxy.size) { _ in
                updater.recalculate()
            }
        }
        .onReceive(updater.timerProgressPublisher(currentTime: clock.makeCurrentTime)) { progress in
            updateState(progress: progress)
        }
        .onAppear {
            updater.recalculate()
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            updater.recalculate()
        }
    }

    private func updateState(progress: CodeTimerAnimationState) {
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

private enum CodeTimerAnimationState {
    case freeze(fraction: Double)
    case startAnimating(startFraction: Double, duration: Double)

    var initialFraction: Double {
        switch self {
        case let .freeze(fraction), let .startAnimating(fraction, _):
            return fraction
        }
    }
}

private extension CodeTimerUpdater {
    /// Maps timer state updates to events that can be rendered by the progress bar.
    func timerProgressPublisher(currentTime: @escaping () -> Double) -> AnyPublisher<CodeTimerAnimationState, Never> {
        timerUpdatedPublisher().map { state in
            let time = currentTime()
            let completed = state.fractionCompleted(at: time)
            let remainingTime = state.remainingTime(at: time)
            return .startAnimating(startFraction: 1 - completed, duration: remainingTime)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

struct CodeTimerHorizontalBarView_Previews: PreviewProvider {
    static var previews: some View {
        CodeTimerHorizontalBarView<MockCodeTimerUpdater>(clock: clock, updater: updater)
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
            .onAppear {
                updater.subject.send(OTPTimerState(startTime: 15, endTime: 60))
            }
    }

    // MARK: - Helpers

    private static let updater: MockCodeTimerUpdater = .init()

    static let clock = EpochClock { 40 }
}
