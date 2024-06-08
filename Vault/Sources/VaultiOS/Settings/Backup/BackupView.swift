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
        case exportPassword
    }

    var body: some View {
        Form {
            createPasswordSection
        }
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case .updatePassword:
                NavigationStack {
                    BackupKeyChangeView(store: backupStore)
                }
            case .exportPassword:
                NavigationStack {
                    BackupKeyExportView()
                }
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
                updateButton
                exportButton
            case .noExistingPassword:
                createButton
            case .error:
                Text(viewModel.strings.backupPasswordErrorTitle)
            }
        } footer: {
            if viewModel.passwordState == .error {
                Text(viewModel.strings.backupPasswordErrorDetail)
            }
        }
    }

    private var createButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            Text(viewModel.strings.backupPasswordCreateTitle)
        }
    }

    private var updateButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            Text(viewModel.strings.backupPasswordUpdateTitle)
        }
    }

    private var exportButton: some View {
        Button {
            modal = .exportPassword
        } label: {
            Text(viewModel.strings.backupPasswordExportTitle)
        }
    }
}
