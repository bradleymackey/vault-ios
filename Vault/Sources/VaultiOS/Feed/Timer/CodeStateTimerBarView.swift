import Foundation
import SwiftUI
import VaultFeed

struct CodeStateTimerBarView<Timer: View>: View {
    var timerView: Timer
    var codeState: OTPCodeState
    var behaviour: VaultItemViewBehaviour

    var body: some View {
        ZStack(alignment: .leading) {
            timerView
                .frame(height: barHeight)
                .clipShape(RoundedRectangle(cornerRadius: barHeight))
                .frame(height: containerHeight)
                .transition(.blurReplace())

            if let textToDisplay {
                LoadingBarLabel(text: textToDisplay)
                    .shimmering(active: isShimmering)
            }
        }
        .animation(.easeOut, value: behaviour)
        .clipShape(RoundedRectangle(cornerRadius: barHeight))
    }

    private var containerHeight: Double {
        24
    }

    private var barHeight: Double {
        if textToDisplay != nil {
            20
        } else {
            12
        }
    }

    private var isShimmering: Bool {
        behaviour != .normal
    }

    private var textToDisplay: String? {
        switch behaviour {
        case let .obfuscate(message):
            message
        case .normal:
            if case let .error(err, _) = codeState {
                err.userTitle
            } else if case .obfuscated = codeState {
                localized(key: "code.updateRequired")
            } else {
                nil
            }
        }
    }
}
