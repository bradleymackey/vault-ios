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

            NavigationLink {
                SettingsDocumentView(title: "About Security", viewModel: AboutSecurityViewModel())
            } label: {
                Label("Security", systemImage: "lock.fill")
            }
        }
        .navigationTitle(Text(viewModel.aboutTitle))
    }
}
