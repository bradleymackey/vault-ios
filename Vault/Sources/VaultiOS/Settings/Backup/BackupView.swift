import Foundation
import FoundationExtensions
import SwiftUI
import VaultFeed

@MainActor
struct BackupView: View {
    @Environment(KeychainBackupPasswordStore.self) var backupStore
    @State private var viewModel: BackupViewModel
    @State private var modal: Modal?

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(store: store))
    }

    enum Modal: IdentifiableSelf {
        case updatePassword
    }

    var body: some View {
        Form {
            createPasswordSection
        }
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case .updatePassword:
                BackupKeyChangeView(store: backupStore)
            }
        }
        .task {
            viewModel.fetchContent()
        }
    }

    private var createPasswordSection: some View {
        Section {
            switch viewModel.passwordState {
            case .loading:
                Text(viewModel.strings.backupPasswordLoadingTitle)
            case .hasExistingPassword:
                Button {
                    modal = .updatePassword
                } label: {
                    Text(viewModel.strings.backupPasswordUpdateTitle)
                }
            case .noExistingPassword:
                Button {
                    modal = .updatePassword
                } label: {
                    Text(viewModel.strings.backupPasswordCreateTitle)
                }
            case .error:
                Text(viewModel.strings.backupPasswordErrorTitle)
            }
        } footer: {
            if viewModel.passwordState == .error {
                Text(viewModel.strings.backupPasswordErrorDetail)
            }
        }
    }
}
