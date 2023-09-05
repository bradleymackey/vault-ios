//
//  CodeSettingsView.swift
//  CodeManager
//
//  Created by Bradley Mackey on 10/08/2023.
//

import SettingsiOS
import SwiftUI
import UICore

struct CodeSettingsView: View {
    var body: some View {
        Form {
            NavigationLink {
                ThirdPartyView()
            } label: {
                Label {
                    Text("Libraries")
                } icon: {
                    RowIcon(icon: Image(systemName: "text.book.closed.fill"), color: .blue)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
