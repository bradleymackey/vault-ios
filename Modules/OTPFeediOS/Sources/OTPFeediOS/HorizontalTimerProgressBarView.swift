import Combine
import SwiftUI

public struct HorizontalTimerProgressBarView: View {
    var color: Color
    /// Recieves events indicating the progress view should update showing the given progress.
    var startSignaller: AnyPublisher<Progress, Never>

    enum Progress {
        case freeze(fraction: Double)
        case startAnimating(startFraction: Double, duration: Double)

        var fraction: Double {
            switch self {
            case let .freeze(fraction), let .startAnimating(fraction, _):
                return fraction
            }
        }

        var timeToComplete: Double? {
            switch self {
            case let .startAnimating(_, duration):
                return duration
            case .freeze:
                return nil
            }
        }
    }

    @State private var currentFractionCompleted = 0.0

    init(
        initialFractionCompleted: Double,
        startSignaller: AnyPublisher<Progress, Never>,
        color: Color = .blue
    ) {
        _currentFractionCompleted = State(initialValue: initialFractionCompleted)
        self.startSignaller = startSignaller
        self.color = color
    }

    public static func fixed(at progress: Double, color: Color) -> HorizontalTimerProgressBarView {
        HorizontalTimerProgressBarView(
            initialFractionCompleted: progress,
            startSignaller: PassthroughSubject().eraseToAnyPublisher(),
            color: color
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray6))
                Rectangle()
                    .fill(color)
                    .frame(width: currentFractionCompleted * proxy.size.width, alignment: .leading)
            }
        }
        .onReceive(startSignaller) { state in
            withAnimation(.linear(duration: 0.15)) {
                currentFractionCompleted = state.fraction
            }
            if let timeToComplete = state.timeToComplete {
                withAnimation(.linear(duration: timeToComplete)) {
                    currentFractionCompleted = 1
                }
            }
        }
    }
}

struct HorizontalTimerProgressBarView_Previews: PreviewProvider {
    static let signallerBlue = PassthroughSubject<HorizontalTimerProgressBarView.Progress, Never>()
    static let signallerRed = PassthroughSubject<HorizontalTimerProgressBarView.Progress, Never>()

    static var previews: some View {
        VStack {
            HorizontalTimerProgressBarView(
                initialFractionCompleted: 0.4,
                startSignaller: signallerBlue.eraseToAnyPublisher(),
                color: .blue
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
            .onAppear {
                signallerBlue.send(.startAnimating(startFraction: 0.4, duration: 2))
            }

            HorizontalTimerProgressBarView(
                initialFractionCompleted: 0.4,
                startSignaller: signallerRed.eraseToAnyPublisher(),
                color: .red
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
            .onAppear {
                signallerRed.send(.freeze(fraction: 0.6))
            }

            HorizontalTimerProgressBarView.fixed(at: 0.5, color: .green)
                .frame(width: 250, height: 20)
                .previewLayout(.fixed(width: 300, height: 300))
        }
    }
}
