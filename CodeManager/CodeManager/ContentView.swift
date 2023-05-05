//
//  ContentView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 05/05/2023.
//

import SwiftUI
import OTPFeediOS

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
