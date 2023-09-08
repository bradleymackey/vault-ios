import Foundation
import OTPFeed
import SwiftUI

struct CodeStateTimerBarView<Timer: View>: View {
    var timerView: Timer
    var codeState: OTPCodeState
    var behaviour: OTPViewBehaviour

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
        .animation(.easeOut, value: behaviour)
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
        behaviour != .normal
    }

    private var textToDisplay: String? {
        switch behaviour {
        case let .obfuscate(message):
            return message
        case .normal:
            if case let .error(err, _) = codeState {
                return err.userTitle
            } else if case .obfuscated = codeState {
                return localized(key: "code.updateRequired")
            } else {
                return nil
            }
        }
    }
}
