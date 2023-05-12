import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct CodeTimerHorizontalBarView: View {
    @ObservedObject var timerState: CodeTimerPeriodState
    var color: Color = .blue
    var backgroundColor: Color = .init(UIColor.systemGray2).opacity(0.3)

    @State private var currentFractionCompleted = 0.0
    @Environment(\.scenePhase) private var scenePhase

    public var body: some View {
        GeometryReader { proxy in
            HorizontalTimerProgressBarView(
                fractionCompleted: currentFractionCompleted,
                color: color,
                backgroundColor: backgroundColor
            )
            .onChange(of: proxy.size) { _ in
                // the size of the viewport has changed
                resetAnimation(animateReset: false)
            }
        }
        .onChange(of: timerState.state) { _ in
            // the time parameters have updated, the timer is likely restarting
            resetAnimation(animateReset: true)
        }
        .onAppear {
            // we have just appeared onscreen
            resetAnimation(animateReset: false)
        }
        .onChange(of: scenePhase) { newScenePhase in
            // we have appeared from background
            if newScenePhase == .active {
                resetAnimation(animateReset: false)
            }
        }
    }

    private func resetAnimation(animateReset: Bool) {
        let animationState = timerState.countdownAnimation()
        withAnimation(.linear(duration: animateReset ? 0.15 : 0)) {
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
            timerState: CodeTimerPeriodState(clock: clock, statePublisher: subject.eraseToAnyPublisher())
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
