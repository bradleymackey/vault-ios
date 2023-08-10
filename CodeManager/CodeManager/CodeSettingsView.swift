//
//  CodeSettingsView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 10/08/2023.
//

import SettingsiOS
import SwiftUI

struct CodeSettingsView: View {
    var body: some View {
        Form {
            NavigationLink {
                ThirdPartyView()
            } label: {
                Label("Third Party Licences", systemImage: "text.book.closed")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}
