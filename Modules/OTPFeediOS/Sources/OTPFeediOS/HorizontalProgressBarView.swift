import Combine
import SwiftUI

public struct HorizontalProgressBarView: View {
    var initialCompletion: Double
    var timeToComplete: Double
    var color: Color
    var startSignaller: AnyPublisher<Void, Never>

    @State private var currentFractionCompleted = 0.0

    init(
        initialCompletion: Double,
        timeToComplete: Double,
        startSignaller: AnyPublisher<Void, Never>,
        color: Color = .blue
    ) {
        _currentFractionCompleted = State(initialValue: initialCompletion)
        self.initialCompletion = initialCompletion
        self.timeToComplete = timeToComplete
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
        .onReceive(startSignaller) { _ in
            withAnimation(.linear(duration: timeToComplete)) {
                currentFractionCompleted = 1
            }
        }
    }
}

struct HorizontalProgressBarView_Previews: PreviewProvider {
    static let signaller = PassthroughSubject<Void, Never>()
    static var previews: some View {
        HorizontalProgressBarView(
            initialCompletion: 0.3,
            timeToComplete: 10,
            startSignaller: signaller.eraseToAnyPublisher()
        )
        .frame(width: 250, height: 50)
        .previewLayout(.fixed(width: 300, height: 300))
        .onAppear {
            signaller.send(())
        }
    }
}
