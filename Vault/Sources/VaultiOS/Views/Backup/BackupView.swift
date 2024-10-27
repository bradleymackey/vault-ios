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
        case importToCurrentlyEmpty(DerivedEncryptionKey?)
        case importAndMerge(DerivedEncryptionKey?)
        case importAndOverride(DerivedEncryptionKey?)
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
                importSection
                keySection(existingPassword: nil)
            case let .fetched(password):
                importSection
                keySection(existingPassword: password)
            }
        }
        .animation(.default, value: dataModel.backupPassword)
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .task {
            await dataModel.reloadItems()
        }
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
                        .onDisappear {
                            // Reset PDF navigation path so next generation starts from the beginning
                            pdfNavigationPath.removeLast(pdfNavigationPath.count)
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
            case let .importToCurrentlyEmpty(backupPassword):
                BackupImportFlowView(viewModel: .init(
                    importContext: .toEmptyVault,
                    dataModel: dataModel,
                    existingBackupPassword: backupPassword,
                    encryptedVaultDecoder: injector.encryptedVaultDecoder
                ))
            case let .importAndMerge(backupPassword):
                BackupImportFlowView(viewModel: .init(
                    importContext: .merge,
                    dataModel: dataModel,
                    existingBackupPassword: backupPassword,
                    encryptedVaultDecoder: injector.encryptedVaultDecoder
                ))
            case let .importAndOverride(backupPassword):
                BackupImportFlowView(viewModel: .init(
                    importContext: .override,
                    dataModel: dataModel,
                    existingBackupPassword: backupPassword,
                    encryptedVaultDecoder: injector.encryptedVaultDecoder
                ))
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

    @ViewBuilder
    private var importSection: some View {
        if dataModel.hasAnyItems {
            hasExistingCodesImportSection
        } else {
            noExistingCodesImportSection
        }
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

    private var noExistingCodesImportSection: some View {
        Section {
            AsyncButton {
                await dataModel.loadBackupPassword()
                modal = .importToCurrentlyEmpty(dataModel.backupPassword.fetchedPassword)
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .accentColor,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Import Backup",
                        subtitle: "Use a backup file to populate your Vault"
                    )
                }
            }
        } header: {
            Text("Import")
        }
    }

    private var hasExistingCodesImportSection: some View {
        Section {
            AsyncButton {
                await dataModel.loadBackupPassword()
                modal = .importAndMerge(dataModel.backupPassword.fetchedPassword)
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.on.square.fill"),
                    color: .accentColor,
                    style: .standard,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Merge Backup",
                        subtitle: "Import a backup file and merge with your existing data. If any items conflict, the most recent version will be used."
                    )
                }
            }

            AsyncButton {
                await dataModel.loadBackupPassword()
                modal = .importAndOverride(dataModel.backupPassword.fetchedPassword)
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .red,
                    style: .standard,
                    alignment: .firstTextBaseline
                ) {
                    TextAndSubtitle(
                        title: "Override Backup",
                        subtitle: "Import a backup file and override any existing data. Any existing data in your vault will be deleted. Warning!"
                    )
                }
                .foregroundStyle(.red)
            }
        } header: {
            Text("Import")
        }
    }
}
