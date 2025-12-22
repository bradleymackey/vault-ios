import SwiftUI
import Toasts
import VaultFeed

struct DeveloperAddOTPItemView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentToast) private var presentToast
    @State private var issuer: String = "mcky.dev"
    @State private var accountName: String = "demo@example.com"
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                TextField("Issuer", text: $issuer)
                TextField("Account Name", text: $accountName)
            }

            Section {
                AsyncButton {
                    try await dataModel.addDemoOTPItemToAutofillStore(
                        issuer: issuer,
                        accountName: accountName,
                    )
                    let toast = ToastValue(icon: Image(systemName: "checkmark"), message: "OTP Item Added")
                    presentToast(toast)
                    dismiss()
                } label: {
                    Text("Add OTP Item")
                } loading: {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Add OTP Item")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
}
