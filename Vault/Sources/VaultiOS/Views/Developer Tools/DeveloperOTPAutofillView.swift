import SwiftUI
import Toasts
import VaultFeed

struct DeveloperOTPAutofillView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(\.presentToast) private var presentToast

    enum Destination: Hashable {
        case addOTPItem
    }

    var body: some View {
        Form {
            Section {
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
            } header: {
                Text("OTP Autofill Store")
            } footer: {
                Text("Manage OTP codes in the iOS AutoFill credential store for testing.")
            }
        }
        .navigationTitle("OTP Autofill")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .addOTPItem:
                DeveloperAddOTPItemView()
            }
        }
    }
}
