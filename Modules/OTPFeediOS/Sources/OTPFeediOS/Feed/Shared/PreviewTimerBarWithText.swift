import Foundation
import OTPFeed
import SwiftUI

struct PreviewTimerBarWithText<Timer: View>: View {
    var timerView: Timer
    var codeState: OTPCodeState
    var isEditing: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            timerView
                .frame(height: 20)

            if isEditing {
                LoadingBarLabel(text: localized(key: "action.tapToEdit"))
                    .shimmering()
            } else if case let .error(err, _) = codeState {
                LoadingBarLabel(text: err.userTitle)
            } else if case .obfuscated = codeState {
                LoadingBarLabel(text: localized(key: "code.updateRequired"))
            }
        }
        .animation(.easeOut, value: isEditing)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
