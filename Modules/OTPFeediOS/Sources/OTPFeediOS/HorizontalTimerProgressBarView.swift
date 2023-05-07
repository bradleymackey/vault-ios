import Combine
import SwiftUI

public struct HorizontalTimerProgressBarView: View {
    @Environment(\.redactionReasons) var redactionReasons

    var color: Color
    var backgroundColor: Color
    /// The wayt that the progress bar completes, by filling or draining.
    var direction: Direction
    /// Recieves events indicating the progress view should update showing the given progress.
    var startSignaller: AnyPublisher<Progress, Never>

    enum Direction {
        case fills
        case drains

        /// The target end fill fraction when the progress bar completes.
        var endingFraction: Double {
            switch self {
            case .fills:
                return 1
            case .drains:
                return 0
            }
        }

        /// The percentage that the bar should be filled.
        func fillFraction(_ actualProgress: Double) -> Double {
            switch self {
            case .fills:
                return actualProgress
            case .drains:
                return 1 - actualProgress
            }
        }
    }

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
        direction: Direction,
        color: Color = .blue,
        backgroundColor: Color = Color(UIColor.systemGray6)
    ) {
        _currentFractionCompleted = State(initialValue: initialFractionCompleted)
        self.startSignaller = startSignaller
        self.direction = direction
        self.color = color
        self.backgroundColor = backgroundColor
    }

    public static func fixed(
        at progress: Double,
        color: Color,
        backgroundColor: Color = Color(UIColor.systemGray6)
    ) -> HorizontalTimerProgressBarView {
        HorizontalTimerProgressBarView(
            initialFractionCompleted: progress,
            startSignaller: PassthroughSubject().eraseToAnyPublisher(),
            direction: .fills,
            color: color,
            backgroundColor: backgroundColor
        )
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                if redactionReasons.isEmpty {
                    Rectangle()
                        .fill(color)
                        .frame(width: currentFractionCompleted * proxy.size.width, alignment: .leading)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray3))
                        .frame(width: proxy.size.width, alignment: .leading)
                }
            }
        }
        .onReceive(startSignaller) { state in
            withAnimation(.linear(duration: 0.15)) {
                currentFractionCompleted = direction.fillFraction(state.fraction)
            }
            if let timeToComplete = state.timeToComplete {
                withAnimation(.linear(duration: timeToComplete)) {
                    currentFractionCompleted = direction.endingFraction
                }
            }
        }
    }
}

struct HorizontalTimerProgressBarView_Previews: PreviewProvider {
    static let signallerBlue = PassthroughSubject<HorizontalTimerProgressBarView.Progress, Never>()
    static let signallerRed = PassthroughSubject<HorizontalTimerProgressBarView.Progress, Never>()
    static let signallerYellow = PassthroughSubject<HorizontalTimerProgressBarView.Progress, Never>()

    static var previews: some View {
        VStack {
            HorizontalTimerProgressBarView(
                initialFractionCompleted: 0.4,
                startSignaller: signallerBlue.eraseToAnyPublisher(),
                direction: .fills,
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
                direction: .fills,
                color: .red
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
            .onAppear {
                signallerRed.send(.freeze(fraction: 0.6))
            }

            HorizontalTimerProgressBarView(
                initialFractionCompleted: 0.1,
                startSignaller: signallerYellow.eraseToAnyPublisher(),
                direction: .drains,
                color: .yellow
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
            .onAppear {
                signallerYellow.send(.startAnimating(startFraction: 0.1, duration: 2))
            }

            HorizontalTimerProgressBarView.fixed(at: 0.5, color: .green)
                .frame(width: 250, height: 20)
                .previewLayout(.fixed(width: 300, height: 300))

            HorizontalTimerProgressBarView.fixed(at: 0.5, color: .green)
                .frame(width: 250, height: 20)
                .redacted(reason: .placeholder)
                .previewLayout(.fixed(width: 300, height: 300))
        }
    }
}
