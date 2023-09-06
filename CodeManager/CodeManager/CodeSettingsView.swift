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
            policySection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                Text("About")
            } label: {
                FormRow(
                    title: "About",
                    image: Image(systemName: "key.fill"),
                    color: .blue
                )
            }
        }
    }

    private var exportSection: some View {
        Section {
            NavigationLink {
                Text("Backup history")
            } label: {
                VStack(alignment: .center) {
                    Text("Last backed up")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Text("23 days ago")
                        .foregroundColor(.primary)
                        .font(.title)
                    Text("2 codes not backed up")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }

            NavigationLink {
                Text("Restore")
            } label: {
                FormRow(
                    title: "Restore from Backup",
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .green
                )
            }

            NavigationLink {
                Text("Export")
            } label: {
                FormRow(
                    title: "Save Backup",
                    image: Image(systemName: "square.and.arrow.up.on.square.fill"),
                    color: .purple
                )
            }
        } header: {
            Text("Export")
        }
    }

    private var policySection: some View {
        Section {
            NavigationLink {
                Text("Info about Open Source, on GitHub")
            } label: {
                FormRow(
                    title: "Open Source",
                    image: Image(systemName: "figure.2.arms.open"),
                    color: .purple
                )
            }

            NavigationLink {
                ThirdPartyView()
            } label: {
                FormRow(
                    title: "Third-Party Libraries",
                    image: Image(systemName: "text.book.closed.fill"),
                    color: .blue
                )
            }
        } header: {
            Text("Policy and Legal")
        }
    }
}
