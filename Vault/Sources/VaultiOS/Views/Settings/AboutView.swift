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
                Label("What are codes?", systemImage: "questionmark.circle.fill")
            }

            backupSection
            dataPrivacySection
        }
        .navigationTitle(Text(viewModel.aboutTitle))
    }
}

// MARK: - Backups

extension AboutView {
    private var backupSection: some View {
        DisclosureGroup {
            Group {
                Text("Backups are important to create as your codes are only stored on this device.")
                Text(
                    "This means if you were to lose this device, your codes will be gone forever and you may not be able to recover your accounts."
                )
                Text("You can backup your codes to iCloud or to paper that you can print off and store securely.")
                Text("Backups are required to be encrypted with a password to ensure only you can restore them.")
            }
            .foregroundColor(.secondary)
        } label: {
            Label("Backups", systemImage: "doc.on.doc.fill")
        }
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
