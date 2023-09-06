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
            aboutSection
            exportSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                ThirdPartyView()
            } label: {
                FormRow(
                    title: "Libraries",
                    image: Image(systemName: "text.book.closed.fill"),
                    color: .blue
                )
            }
        }
    }

    private var exportSection: some View {
        Section {
            NavigationLink {
                Text("Export")
            } label: {
                FormRow(
                    title: "Save Backup",
                    image: Image(systemName: "square.and.arrow.up.on.square.fill"),
                    color: .red
                )
            }
        }
    }
}
