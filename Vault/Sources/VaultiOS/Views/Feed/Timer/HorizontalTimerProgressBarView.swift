import Combine
import SwiftUI

public struct HorizontalTimerProgressBarView: View {
    var fractionCompleted: Double
    var color: Color
    var backgroundColor: Color = .init(UIColor.systemGray6)

    @Environment(\.redactionReasons) var redactionReasons

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                Rectangle()
                    .fill(color)
                    .frame(
                        width: isPlaceholder ? 0 : fractionCompleted * proxy.size.width,
                        alignment: .leading
                    )
            }
        }
    }

    private var isPlaceholder: Bool {
        redactionReasons.contains(.placeholder)
    }
}

struct HorizontalTimerProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HorizontalTimerProgressBarView(
                fractionCompleted: 0.4,
                color: .blue
            )
            .frame(width: 250, height: 20)
            .redacted(reason: .placeholder)
            .previewLayout(.fixed(width: 300, height: 300))

            HorizontalTimerProgressBarView(
                fractionCompleted: 0.4,
                color: .blue
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))

            HorizontalTimerProgressBarView(
                fractionCompleted: 0.6,
                color: .red
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))

            HorizontalTimerProgressBarView(
                fractionCompleted: 0.75,
                color: .red,
                backgroundColor: .yellow
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
        }
    }
}
