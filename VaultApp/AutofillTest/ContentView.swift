//
//  ContentView.swift
//  AutofillTest
//
//  Created by Bradley Mackey on 01/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var otpText = ""
    var body: some View {
        List {
            TextField("OTP Code (example.com)", text: $otpText)
                               .keyboardType(.numberPad)
                               .textContentType(.oneTimeCode)
                               .autocorrectionDisabled()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
