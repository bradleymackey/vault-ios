import SwiftUI

struct OTPAutofillDemoView: View {
    @State private var otpText = ""
    var body: some View {
        Form {
            TextField("OTP Code", text: $otpText)
                .textContentType(.oneTimeCode)
        }
        .navigationTitle("Autofill")
        .navigationBarTitleDisplayMode(.inline)
    }
}
