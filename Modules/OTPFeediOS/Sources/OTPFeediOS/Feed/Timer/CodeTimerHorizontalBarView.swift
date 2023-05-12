import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct CodeTimerHorizontalBarView: View {
    @ObservedObject var timerState: CodeTimerPeriodState
    var clock: EpochClock
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
                resetAnimation(timerState: timerState.state)
            }
        }
        .onChange(of: timerState.state) { timerState in
            resetAnimation(timerState: timerState)
        }
        .onAppear {
            resetAnimation(timerState: timerState.state)
        }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .active {
                resetAnimation(timerState: timerState.state)
            }
        }
    }

    private func resetAnimation(timerState: OTPTimerState?) {
        let animationState = CodeTimerAnimationState.countdownFrom(
            timerState: timerState,
            currentTime: clock.currentTime
        )
        withAnimation(.linear(duration: 0.15)) {
            currentFractionCompleted = animationState.initialFraction
        }
        if case let .animate(_, duration) = animationState {
            withAnimation(.linear(duration: duration)) {
                currentFractionCompleted = 0
            }
        }
    }
}

struct CodeTimerHorizontalBarView_Previews: PreviewProvider {
    static var previews: some View {
        CodeTimerHorizontalBarView(
            timerState: CodeTimerPeriodState(statePublisher: subject.eraseToAnyPublisher()),
            clock: clock
        )
        .frame(width: 250, height: 20)
        .previewLayout(.fixed(width: 300, height: 300))
        .onAppear {
            subject.send(OTPTimerState(startTime: 15, endTime: 60))
        }
    }

    // MARK: - Helpers

    private static let subject: PassthroughSubject<OTPTimerState, Never> = .init()

    static let clock = EpochClock { 40 }
}
