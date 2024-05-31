import Foundation
import FoundationExtensions
import SwiftUI
import VaultFeed

struct BackupView: View {
    @Environment(KeychainBackupPasswordStore.self) var backupStore
    @State private var modal: Modal?

    enum Modal: IdentifiableSelf {
        case updatePassword
    }

    var body: some View {
        Form {
            createPasswordSection
        }
        .navigationTitle(Text("Backup"))
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case .updatePassword:
                BackupKeyChangeView(store: backupStore)
            }
        }
    }

    private var createPasswordSection: some View {
        Section {
            Button {
                modal = .updatePassword
            } label: {
                Text("Set Backup Password")
            }
        }
    }
}
