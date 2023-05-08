import Combine
import SwiftUI

public struct HorizontalTimerProgressBarView: View {
    @Binding var fractionCompleted: Double
    var color: Color
    var backgroundColor: Color = .init(UIColor.systemGray6)

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                Rectangle()
                    .fill(color)
                    .frame(width: fractionCompleted * proxy.size.width, alignment: .leading)
            }
        }
    }
}

struct HorizontalTimerProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HorizontalTimerProgressBarView(
                fractionCompleted: .constant(0.4),
                color: .blue
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))

            HorizontalTimerProgressBarView(
                fractionCompleted: .constant(0.6),
                color: .red
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))

            HorizontalTimerProgressBarView(
                fractionCompleted: .constant(0.75),
                color: .red,
                backgroundColor: .yellow
            )
            .frame(width: 250, height: 20)
            .previewLayout(.fixed(width: 300, height: 300))
        }
    }
}
