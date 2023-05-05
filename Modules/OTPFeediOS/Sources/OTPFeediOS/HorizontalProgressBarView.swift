import Combine
import SwiftUI

public struct HorizontalProgressBarView: View {
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
            withAnimation(.easeOut(duration: 0.3)) {
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

struct HorizontalProgressBarView_Previews: PreviewProvider {
    static let signaller = PassthroughSubject<HorizontalProgressBarView.Progress, Never>()
    static var previews: some View {
        HorizontalProgressBarView(
            initialFractionCompleted: 0.4,
            startSignaller: signaller.eraseToAnyPublisher(),
            color: .blue
        )
        .frame(width: 250, height: 50)
        .previewLayout(.fixed(width: 300, height: 300))
        .onAppear {
            signaller.send(.startAnimating(startFraction: 0.4, duration: 2))
        }

        HorizontalProgressBarView(
            initialFractionCompleted: 0.4,
            startSignaller: signaller.eraseToAnyPublisher(),
            color: .red
        )
        .frame(width: 250, height: 50)
        .previewLayout(.fixed(width: 300, height: 300))
        .onAppear {
            signaller.send(.freeze(fraction: 0.6))
        }
    }
}
