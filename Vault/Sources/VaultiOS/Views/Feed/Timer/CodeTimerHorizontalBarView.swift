import Combine
import SwiftUI
import UniformTypeIdentifiers
import VaultFeed

struct CodeTimerHorizontalBarView: View {
    var timerState: OTPCodeTimerPeriodState
    var color: Color = .blue
    var backgroundColor: Color = .init(UIColor.systemGray2).opacity(0.3)

    @State private var currentFractionCompleted = 1.0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(VaultInjector.self) private var injector

    var body: some View {
        GeometryReader { proxy in
            HorizontalTimerProgressBarView(
                fractionCompleted: currentFractionCompleted,
                color: color,
                backgroundColor: backgroundColor
            )
            .onChange(of: proxy.size) { _, _ in
                // the size of the viewport has changed
                resetAnimation(animateReset: false)
            }
        }
        .onChange(of: timerState.animationState) { _, _ in
            resetAnimation(animateReset: true)
        }
        .onAppear {
            // we have just appeared onscreen
            resetAnimation(animateReset: false)
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            // we have appeared from background
            if newScenePhase == .active {
                resetAnimation(animateReset: false)
            }
        }
    }

    private func resetAnimation(animateReset: Bool) {
        let currentTime = injector.clock.currentTime
        withAnimation(
            .linear(duration: animateReset ? 0.15 : 0), {
                currentFractionCompleted = timerState.animationState.initialFraction(currentTime: currentTime)
            },
            completion: {
                if case let .animate(state) = timerState.animationState {
                    withAnimation(.linear(duration: state.remainingTime(at: currentTime))) {
                        currentFractionCompleted = 0
                    }
                }
            }
        )
    }
}

#Preview {
    let subject: PassthroughSubject<OTPCodeTimerState, Never> = .init()
    return CodeTimerHorizontalBarView(
        timerState: OTPCodeTimerPeriodState(statePublisher: subject.eraseToAnyPublisher())
    )
    .frame(width: 250, height: 20)
    .previewLayout(.fixed(width: 300, height: 300))
    .onAppear {
        subject.send(OTPCodeTimerState(startTime: 15, endTime: 60))
    }
    .environment(VaultInjector(
        clock: EpochClock { 40 },
        intervalTimer: IntervalTimerImpl(),
        backupEventLogger: BackupEventLoggerMock(),
        vaultKeyDeriverFactory: VaultKeyDeriverFactoryImpl(),
        defaults: Defaults(userDefaults: .standard)
    ))
}
