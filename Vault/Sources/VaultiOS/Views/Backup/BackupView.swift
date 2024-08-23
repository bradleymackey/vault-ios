import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(DeviceAuthenticationService.self) var authenticationService
    @Environment(VaultInjector.self) var injector
    @State private var viewModel = BackupViewModel()
    @State private var modal: Modal?

    enum Modal: IdentifiableSelf {
        case updatePassword
        case exportPassword(BackupPassword)
        case importPassword
        case pdfBackup(BackupPassword)
    }

    var body: some View {
        Form {
            if let password = dataModel.backupPassword.fetchedPassword {
                currentBackupsSection(password: password)
            }

            switch dataModel.backupPassword {
            case .error:
                authenticateSection(isError: true)
            case .notFetched:
                authenticateSection(isError: false)
            case .notCreated:
                currentKeySection(existingPassword: nil)
            case let .fetched(password):
                currentKeySection(existingPassword: password)
                overrideKeySection(existingPassword: password)
            }
        }
        .animation(.default, value: dataModel.backupPassword)
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case let .pdfBackup(password):
                NavigationStack {
                    BackupCreatePDFView(viewModel: .init(
                        backupPassword: password,
                        dataModel: dataModel,
                        clock: injector.clock,
                        backupEventLogger: injector.backupEventLogger,
                        defaults: injector.defaults,
                        fileManager: injector.fileManager
                    ))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Done")
                            }
                        }
                    }
                }
            case .updatePassword:
                NavigationStack {
                    BackupKeyChangeView(viewModel: .init(
                        dataModel: dataModel,
                        authenticationService: authenticationService,
                        deriverFactory: injector.vaultKeyDeriverFactory
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
                    BackupKeyImportView(viewModel: .init(dataModel: dataModel), intervalTimer: injector.intervalTimer)
                }
            }
        }
    }

    private func currentBackupsSection(password: BackupPassword) -> some View {
        Section {
            LastBackupSummaryView(
                lastBackup: dataModel.lastBackupEvent,
                currentHash: dataModel.currentPayloadHash
            )

            Button {
                modal = .pdfBackup(password)
            } label: {
                FormRow(image: Image(systemName: "printer.filled.and.paper"), color: .blue, style: .standard) {
                    Text("Create PDF Backup")
                }
            }
        }
        .transition(.slide)
    }

    private func currentKeySection(existingPassword: BackupPassword?) -> some View {
        Section {
            if let existingPassword {
                exportButton(password: existingPassword)
            } else {
                createButton
                importButton
            }
        } header: {
            Text("Encryption Key")
        }
        .transition(.slide)
    }

    private func overrideKeySection(existingPassword _: BackupPassword) -> some View {
        Section {
            updateButton
            importButton
        } header: {
            Text("Override Encryption Key")
        }
        .transition(.slide)
    }

    private func authenticateSection(isError: Bool) -> some View {
        Section {
            PlaceholderView(
                systemIcon: isError ? "key.slash.fill" : "lock.fill",
                title: isError ? viewModel.strings.backupPasswordErrorTitle : viewModel.strings
                    .backupPasswordLoadingTitle,
                subtitle: isError ? viewModel.strings
                    .backupPasswordErrorDetail : "Authenticate to access backup settings"
            )
            .foregroundStyle(.secondary)
            .padding()
            .containerRelativeFrame(.horizontal)

            authenticateButton
        }
        .transition(.slide)
    }

    private var authenticateButton: some View {
        AsyncButton(progressAlignment: .center) {
            await dataModel.loadBackupPassword()
        } label: {
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .blue, style: .standard) {
                Text("Authenticate")
            }
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
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .red, style: .standard) {
                Text(viewModel.strings.backupPasswordUpdateTitle)
            }
        }
    }

    private func exportButton(password: BackupPassword) -> some View {
        Button {
            modal = .exportPassword(password)
        } label: {
            FormRow(image: Image(systemName: "square.and.arrow.up.fill"), color: .green, style: .standard) {
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
