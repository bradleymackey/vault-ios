import SwiftUI

struct ContentView: View {
    @State private var otpText = ""
    var body: some View {
        List {
            TextField("OTP Code (mcky.dev)", text: $otpText)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
        }
    }
}

#Preview {
    ContentView()
}
