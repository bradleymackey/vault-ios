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
        switch behaviour {
        case .normal: false
        case .editingState: true
        }
    }

    private var textToDisplay: String? {
        switch behaviour {
        case let .editingState(message):
            message
        case .normal:
            switch codeState {
            case let .obfuscated(obfuscationReason):
                switch obfuscationReason {
                case .expiry:
                    localized(key: "code.updateRequired")
                case .privacy:
                    nil
                }
            case let .error(presentationError, _):
                presentationError.userTitle
            case .visible, .notReady, .finished:
                nil
            }
        }
    }
}
