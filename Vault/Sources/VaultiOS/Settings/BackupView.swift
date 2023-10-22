import Foundation
import SwiftUI

struct BackupView: View {
    @State private var isBackupPasswordSet = false

    var body: some View {
        Form {
            if !isBackupPasswordSet {
                createPasswordSection
            }

            if isBackupPasswordSet {
                icloudSection
                paperSection
                updatePasswordSection
            }
        }
        .navigationTitle(Text("Backup"))
    }

    private var createPasswordSection: some View {
        Section {
            Button {
//                print("set backup password in keychain")
                isBackupPasswordSet = true
            } label: {
                Text("Set Backup Password")
            }
        }
    }

    private var updatePasswordSection: some View {
        Section {
            Button {
//                print("update backup password in keychain")
//                print("note: old backups will still require your old password, you should destroy them")
            } label: {
                Text("Change Backup Password")
            }

            Button {
//                print("disable backups")
//                print("note: any existing backups will still work using the backup password at their time of creation")
                isBackupPasswordSet = false
            } label: {
                Text("Disable Backups")
                    .font(.body.bold())
                    .foregroundStyle(.red)
            }
        }
    }

    private var icloudSection: some View {
        Section {
            Text("iCloud backup options, including enable automatic backup")
        }
    }

    private var paperSection: some View {
        Section {
            Text("Paper backup options, export current codes and print")
        }
    }
}
