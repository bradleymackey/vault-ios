import SwiftUI
import Toasts
import VaultFeed

struct DeveloperToolsHomeView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(\.presentToast) private var presentToast

    enum Destination: Hashable {
        case createItems
        case addOTPItem
    }

    var body: some View {
        Form {
            NavigationLink(value: Destination.createItems) {
                Text("Create Items")
            }

            Section("OTP Autofill Store") {
                NavigationLink(value: Destination.addOTPItem) {
                    Text("Add OTP Item")
                }

                AsyncButton {
                    try await dataModel.clearOTPAutofillStore()
                    let toast = ToastValue(icon: Image(systemName: "checkmark"), message: "All OTP Items Cleared")
                    presentToast(toast)
                } label: {
                    Text("Clear All OTP Items")
                } loading: {
                    ProgressView()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Developer")
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .createItems:
                DeveloperCreateItemsView()
            case .addOTPItem:
                DeveloperAddOTPItemView()
            }
        }
    }
}
