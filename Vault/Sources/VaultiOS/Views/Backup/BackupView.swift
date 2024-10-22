import Foundation
import SwiftUI
import VaultFeed
import VaultKeygen

@MainActor
struct BackupView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(DeviceAuthenticationService.self) var authenticationService
    @Environment(VaultInjector.self) var injector
    @State private var viewModel = BackupViewModel()
    @State private var modal: Modal?
    @State private var pdfNavigationPath = NavigationPath()

    enum Modal: IdentifiableSelf {
        case updatePassword
        case pdfBackup(DerivedEncryptionKey)
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
                keySection(existingPassword: nil)
            case let .fetched(password):
                keySection(existingPassword: password)
            }
        }
        .animation(.default, value: dataModel.backupPassword)
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
            case let .pdfBackup(password):
                NavigationStack(path: $pdfNavigationPath) {
                    BackupCreatePDFView(
                        viewModel: .init(
                            backupPassword: password,
                            dataModel: dataModel,
                            clock: injector.clock,
                            backupEventLogger: injector.backupEventLogger,
                            defaults: injector.defaults,
                            fileManager: injector.fileManager
                        ),
                        navigationPath: $pdfNavigationPath
                    )
                    .navigationDestination(for: BackupCreatePDFViewModel.GeneratedPDF.self, destination: { pdf in
                        BackupGeneratedPDFView(pdf: pdf) {
                            modal = nil
                        }
                    })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                modal = nil
                            } label: {
                                Text("Cancel")
                                    .foregroundStyle(.red)
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
            }
        }
    }

    private func currentBackupsSection(password: DerivedEncryptionKey) -> some View {
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

    private func keySection(existingPassword: DerivedEncryptionKey?) -> some View {
        Section {
            if existingPassword != nil {
                updateButton
            } else {
                createButton
            }
        } header: {
            Text("Encryption Key")
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
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .accentColor, style: .standard) {
                Text("Authenticate")
            }
        }
    }

    private var createButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .accentColor, style: .prominent) {
                Text(viewModel.strings.backupPasswordCreateTitle)
            }
        }
    }

    private var updateButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            FormRow(image: Image(systemName: "arrow.triangle.2.circlepath"), color: .accentColor, style: .prominent) {
                Text(viewModel.strings.backupPasswordUpdateTitle)
            }
        }
    }
}
