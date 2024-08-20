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
                        clock: clock
                    ))
                }
            case .updatePassword:
                NavigationStack {
                    BackupKeyChangeView(viewModel: .init(
                        dataModel: dataModel,
                        authenticationService: authenticationService,
                        deriverFactory: VaultKeyDeriverFactoryImpl()
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
    }

    private func currentBackupsSection(password: BackupPassword) -> some View {
        Section {
            VStack {
                Text("Backups")
                    .font(.headline)

                Text("Most recent")
                Text("Any changes since last backup?")
            }
            .containerRelativeFrame(.horizontal)

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
