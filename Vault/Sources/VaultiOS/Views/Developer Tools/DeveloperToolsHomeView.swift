import SwiftUI

struct DeveloperToolsHomeView: View {
    enum Destination: Hashable {
        case otpAutofill
        case createItems
    }

    var body: some View {
        Form {
            NavigationLink(value: Destination.otpAutofill) {
                Text("OTP Autofill")
            }
            NavigationLink(value: Destination.createItems) {
                Text("Create Items")
            }
        }
        .navigationTitle("Developer")
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .otpAutofill:
                OTPAutofillDemoView()
            case .createItems:
                DeveloperCreateItemsView()
            }
        }
    }
}
