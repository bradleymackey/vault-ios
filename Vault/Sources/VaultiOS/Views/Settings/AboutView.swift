import Foundation
import SwiftUI
import VaultSettings

struct AboutView: View {
    var viewModel: SettingsViewModel

    var body: some View {
        Form {
            NavigationLink {
                SettingsDocumentView(title: "About Codes", viewModel: AboutCodesViewModel())
            } label: {
                Label("What are 2FA codes?", systemImage: "questionmark.circle.fill")
            }

            NavigationLink {
                SettingsDocumentView(title: "About Backups", viewModel: AboutBackupsViewModel())
            } label: {
                Label("Backups", systemImage: "doc.on.doc.fill")
            }

            dataPrivacySection
        }
        .navigationTitle(Text(viewModel.aboutTitle))
    }
}

// MARK: - Data Privacy

extension AboutView {
    private var dataPrivacySection: some View {
        DisclosureGroup {
            Group {
                Text("Your codes are only visible on the device you set them up on.")
                Text(
                    "They are only backed up to iCloud with your explicit approval, and are not sent to any other server."
                )
                Text(
                    "Individuals that are particularly security conscious should build the app from source (as this app is open-source)."
                )
            }
            .foregroundColor(.secondary)
        } label: {
            Label("Data Privacy", systemImage: "lock.fill")
        }
    }
}
