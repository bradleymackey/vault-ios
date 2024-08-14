import Foundation
import FoundationExtensions
import SwiftUI
import VaultFeed

@MainActor
struct BackupView: View {
    @Environment(BackupPasswordStoreImpl.self) var backupStore
    @State private var viewModel: BackupViewModel
    @State private var modal: Modal?

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(store: store))
    }

    enum Modal: IdentifiableSelf {
        case updatePassword
        case exportPassword
        case importPassword
        case pdfBackup
    }

    var body: some View {
        Form {
            createExportSection
            createPasswordSection
        }
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case .pdfBackup:
                NavigationStack {
                    Text("PDF Backup")
                }
            case .updatePassword:
                NavigationStack {
                    BackupKeyChangeView(viewModel: .init(
                        store: backupStore,
                        deriverFactory: ApplicationKeyDeriverFactoryImpl()
                    ))
                }
            case .exportPassword:
                NavigationStack {
                    BackupKeyExportView(store: backupStore)
                }
            case .importPassword:
                NavigationStack {
                    BackupKeyImportView(store: backupStore)
                }
            }
        }
        .task {
            viewModel.fetchContent()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var createExportSection: some View {
        Section {
            Button {
                modal = .pdfBackup
            } label: {
                FormRow(image: Image(systemName: "printer.filled.and.paper"), color: .blue, style: .standard) {
                    Text("Create PDF Backup")
                }
            }
        } header: {
            Text("Backups")
        }
    }

    private var createPasswordSection: some View {
        Section {
            switch viewModel.passwordState {
            case .loading:
                PlaceholderView(systemIcon: "lock.fill", title: viewModel.strings.backupPasswordLoadingTitle)
                    .foregroundStyle(.secondary)
                    .padding()
                    .containerRelativeFrame(.horizontal)
            case .hasExistingPassword:
                updateButton
                exportButton
                importButton
            case .noExistingPassword:
                createButton
                importButton
            case .error:
                PlaceholderView(
                    systemIcon: "key.slash.fill",
                    title: viewModel.strings.backupPasswordErrorTitle,
                    subtitle: viewModel.strings.backupPasswordErrorDetail
                )
                .foregroundStyle(.secondary)
                .padding()
                .containerRelativeFrame(.horizontal)
            }
        } header: {
            Text(viewModel.strings.backupPasswordSectionTitle)
        }
    }

    private var createButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .blue, style: .standard) {
                Text(viewModel.strings.backupPasswordCreateTitle)
            }
        }
    }

    private var updateButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .purple, style: .standard) {
                Text(viewModel.strings.backupPasswordUpdateTitle)
            }
        }
    }

    private var exportButton: some View {
        Button {
            modal = .exportPassword
        } label: {
            FormRow(image: Image(systemName: "square.and.arrow.up.fill"), color: .blue, style: .standard) {
                Text(viewModel.strings.backupPasswordExportTitle)
            }
        }
    }

    private var importButton: some View {
        Button {
            modal = .importPassword
        } label: {
            FormRow(image: Image(systemName: "square.and.arrow.down.fill"), color: .blue, style: .standard) {
                Text(viewModel.strings.backupPasswordImportTitle)
            }
        }
    }
}
