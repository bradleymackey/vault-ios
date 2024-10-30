import SwiftUI

struct DemoViewHome: View {
    enum Destination: Hashable {
        case otpAutofill
    }

    var body: some View {
        Form {
            NavigationLink(value: Destination.otpAutofill) {
                Text("OTP Autofill")
            }
        }
        .navigationTitle("Demos")
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .otpAutofill:
                OTPAutofillDemoView()
            }
        }
    }
}
