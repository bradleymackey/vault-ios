import Foundation
import SwiftUI
import VaultFeed

struct OTPKeyValidationView: View {
    var validationState: FieldValidationState
    var validTitle: String
    var invalidTitle: String
    var errorTitle: String

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            icon
            Text(titleText)
                .foregroundStyle(accentColor)
        }
        .multilineTextAlignment(.center)
        .font(.callout)
        .foregroundStyle(.primary)
        .textCase(.none)
        .frame(minHeight: 80, alignment: .center)
    }

    private var titleText: String {
        switch validationState {
        case .valid: validTitle
        case .invalid: invalidTitle
        case let .error(.some(message)): message
        case .error(.none): errorTitle
        }
    }

    private var accentColor: some ShapeStyle {
        switch validationState {
        case .valid: Color.green
        case .invalid: Color.secondary
        case .error: Color.red
        }
    }

    private var icon: some View {
        Image(systemName: systemIconName)
            .font(.largeTitle)
            .foregroundStyle(accentColor)
            .shimmering(active: validationState == .invalid)
    }

    private var systemIconName: String {
        switch validationState {
        case .valid, .invalid: "entry.lever.keypad"
        case .error: "entry.lever.keypad.trianglebadge.exclamationmark.fill"
        }
    }
}

#Preview {
    OTPKeyValidationView(validationState: .valid, validTitle: "any", invalidTitle: "any", errorTitle: "any")
}
