import Combine
import OTPCore
import OTPFeed
import SwiftUI

public struct CodeTimerHorizontalBarView: View {
    @ObservedObject var codeTimerProgressState: CodeTimerProgressState
    var color: Color = .blue
    var backgroundColor: Color = .init(UIColor.systemGray2).opacity(0.3)

    @State private var fractionCompleted: Double = 0
    @Environment(\.scenePhase) var scenePhase

    public var body: some View {
        GeometryReader { reader in
            HorizontalTimerProgressBarView(
                fractionCompleted: $fractionCompleted,
                color: color,
                backgroundColor: backgroundColor
            )
            .onChange(of: reader.size) { _ in
                let currentProgress = codeTimerProgressState.progress
                resetAnimation(to: currentProgress)
            }
        }
        .onChange(of: codeTimerProgressState.progress) { progress in
            resetAnimation(to: progress)
        }
        .onAppear {
            let currentProgress = codeTimerProgressState.progress
            resetAnimation(to: currentProgress)
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                let currentProgress = codeTimerProgressState.progress
                resetAnimation(to: currentProgress)
            }
        }
    }

    private func resetAnimation(to progress: CodeTimerProgress) {
        withAnimation(.linear(duration: 0.15)) {
            fractionCompleted = progress.initialFraction
        }
        if case let .startAnimating(_, duration) = progress {
            withAnimation(.linear(duration: duration)) {
                fractionCompleted = 0
            }
        }
    }
}

// struct CodeTimerHorizontalBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        CodeTimerHorizontalBarView<MockCodeTimerUpdater>(clock: clock, updater: updater)
//            .frame(width: 250, height: 20)
//            .previewLayout(.fixed(width: 300, height: 300))
//            .onAppear {
//                updater.subject.send(OTPTimerState(startTime: 15, endTime: 60))
//            }
//    }
//
//    // MARK: - Helpers
//
//    private static let updater: MockCodeTimerUpdater = .init()
//
//    static let clock = EpochClock { 40 }
// }
