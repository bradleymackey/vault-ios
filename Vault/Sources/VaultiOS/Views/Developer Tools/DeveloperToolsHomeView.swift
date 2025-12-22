import SwiftUI
import VaultFeed

struct DeveloperToolsHomeView: View {
    enum Destination: Hashable {
        case createItems
        case otpAutofill
    }

    var body: some View {
        Form {
            NavigationLink(value: Destination.createItems) {
                Text("Create Items")
            }

            NavigationLink(value: Destination.otpAutofill) {
                Text("OTP Autofill")
            }
        }
        .navigationTitle("Developer")
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .createItems:
                DeveloperCreateItemsView()
            case .otpAutofill:
                DeveloperOTPAutofillView()
            }
        }
    }
}
