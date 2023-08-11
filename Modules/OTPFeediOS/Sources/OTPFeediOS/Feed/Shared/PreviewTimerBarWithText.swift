import Foundation
import OTPFeed
import SwiftUI

struct PreviewTimerBarWithText<Timer: View>: View {
    var timerView: Timer
    var codeState: OTPCodeState

    var body: some View {
        ZStack(alignment: .leading) {
            timerView
                .frame(height: 20)

            switch codeState {
            case let .error(err, _):
                LoadingBarLabel(text: err.userTitle)
            case .editing:
                LoadingBarLabel(text: localized(key: "action.tapToEdit"))
                    .shimmering()
            case .finished, .visible, .notReady:
                EmptyView()
            }
        }
        .animation(.easeOut, value: codeState)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
