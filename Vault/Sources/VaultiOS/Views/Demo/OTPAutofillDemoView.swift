import SwiftUI

struct OTPAutofillDemoView: View {
    @State private var otpText = ""
    var body: some View {
        Form {
            Section {
                TextField("OTP Code", text: $otpText)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .autocorrectionDisabled()
            } footer: {
                Text("Note that OTP autofill from apps is currently broken in iOS 18. No suggestions will be offered.")
            }
        }
        .navigationTitle("Autofill")
        .navigationBarTitleDisplayMode(.inline)
    }
}
