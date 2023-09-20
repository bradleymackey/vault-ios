import Foundation
import OTPSettings
import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            whatAreCodesSection
            backupSection
            dataPrivacySection
        }
        .navigationTitle(Text(viewModel.aboutTitle))
    }
}

// MARK: - What are Codes

extension AboutView {
    private var whatAreCodesSection: some View {
        DisclosureGroup {
            Group {
                Text(
                    "Two-factor authentication (2FA) codes are used to provide an extra layer of security when logging into websites."
                )
                Text(
                    "Some websites offer this ability to make your account more secure, as you need a username, password and a code to login."
                )
                Text(
                    "Once setup, only your device knows how to generate these codes for your account. This means that you need physical access to this device to login to the account. The advantage of this is that if your username and password are compromised, a hacker still won't be able to login to your account because they don't have access to this device with your 2FA code."
                )
                Text("It's a best-practice to setup 2FA for all your accounts that support this.")
            }
            .foregroundColor(.secondary)
        } label: {
            Label("What are codes?", systemImage: "questionmark.circle.fill")
        }
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
