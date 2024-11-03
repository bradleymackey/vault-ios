import Foundation
import SwiftUI
import VaultSettings

struct HelpView: View {
    var viewModel: SettingsViewModel

    var body: some View {
        Form {
            generalSection
            backupsSection
        }
        .navigationTitle(Text(viewModel.helpTitle))
    }

    private var generalSection: some View {
        Section {
            NavigationLink {
                SettingsDocumentView(title: "About Codes", content: FAQCodesFileContent())
            } label: {
                Label("What is a 'code'?", systemImage: "questionmark.circle.fill")
            }
        } header: {
            Label("General", systemImage: "info.circle.fill")
        }
    }

    private var backupsSection: some View {
        Section {
            NavigationLink {
                SettingsDocumentView(title: "About Backups", content: FAQBackupsGeneralFileContent())
            } label: {
                Label("Why should I make backups?", systemImage: "questionmark.circle.fill")
            }

            NavigationLink {
                SettingsDocumentView(title: "Backup Security", content: FAQBackupsSecurityFileContent())
            } label: {
                Label("Are backups secure?", systemImage: "lock.fill")
            }
        } header: {
            Label("Backups", systemImage: "doc.on.doc.fill")
        }
    }
}
