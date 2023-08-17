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
                .frame(height: barHeight)
                .clipShape(RoundedRectangle(cornerRadius: barHeight))
                .frame(height: containerHeight)

            if let textToDisplay {
                LoadingBarLabel(text: textToDisplay)
                    .shimmering(active: isShimmering)
            }
        }
        .animation(.easeOut, value: isEditing)
        .clipShape(RoundedRectangle(cornerRadius: containerHeight))
    }

    private var containerHeight: Double {
        24
    }

    private var barHeight: Double {
        if textToDisplay != nil {
            return 20
        } else {
            return 12
        }
    }

    private var isShimmering: Bool {
        isEditing
    }

    private var textToDisplay: String? {
        if isEditing {
            return localized(key: "action.tapToEdit")
        } else if case let .error(err, _) = codeState {
            return err.userTitle
        } else if case .obfuscated = codeState {
            return localized(key: "code.updateRequired")
        } else {
            return nil
        }
    }
}
