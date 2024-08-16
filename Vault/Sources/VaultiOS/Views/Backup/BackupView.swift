import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
struct BackupView: View {
    @Environment(EpochClock.self) var clock
    @Environment(VaultDataModel.self) var dataModel
    @Environment(DeviceAuthenticationService.self) var authenticationService
    @State private var viewModel = BackupViewModel()
    @State private var modal: Modal?
    @State private var noPasswordAlert = false

    enum Modal: IdentifiableSelf {
        case updatePassword
        case exportPassword(BackupPassword)
        case importPassword
        case pdfBackup(BackupPassword)
    }

    var body: some View {
        Form {
            createPasswordSection
            if let password = dataModel.backupPassword.fetchedPassword {
                createExportSection(password: password)
            }
        }
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .alert("Backup Password Error", isPresented: $noPasswordAlert, actions: {
            Button("Reload", role: .cancel) {
                Task {
                    await dataModel.loadBackupPassword()
                }
            }
            Button("Cancel", role: .destructive) {}
        }, message: {
            Text("Unable to load your encryption key. Please try again.")
        })
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case let .pdfBackup(password):
                NavigationStack {
                    BackupCreatePDFView(viewModel: .init(
                        backupPassword: password,
                        dataModel: dataModel,
                        clock: clock
                    ))
                }
            case .updatePassword:
                NavigationStack {
                    BackupKeyChangeView(viewModel: .init(
                        dataModel: dataModel,
                        authenticationService: authenticationService,
                        deriverFactory: ApplicationKeyDeriverFactoryImpl()
                    ))
                }
            case let .exportPassword(password):
                NavigationStack {
                    BackupKeyExportView(viewModel: .init(
                        exporter: .init(backupPassword: password),
                        authenticationService: authenticationService
                    ))
                }
            case .importPassword:
                NavigationStack {
                    BackupKeyImportView(viewModel: .init(dataModel: dataModel))
                }
            }
        }
        .task {
            await dataModel.loadBackupPassword()
        }
    }

    private func createExportSection(password: BackupPassword) -> some View {
        Section {
            Button {
                modal = .pdfBackup(password)
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
            switch dataModel.backupPassword {
            case .notFetched:
                PlaceholderView(systemIcon: "lock.fill", title: viewModel.strings.backupPasswordLoadingTitle)
                    .foregroundStyle(.secondary)
                    .padding()
                    .containerRelativeFrame(.horizontal)
            case let .fetched(password):
                updateButton
                exportButton(password: password)
                importButton
            case .notCreated:
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

    private func exportButton(password: BackupPassword) -> some View {
        Button {
            modal = .exportPassword(password)
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
