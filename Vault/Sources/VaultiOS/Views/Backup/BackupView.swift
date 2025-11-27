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
            switch dataModel.backupPassword {
            case .error:
                authenticateSection(isError: true)
            case .notFetched:
                authenticateSection(isError: false)
            case .notCreated:
                if dataModel.hasAnyItems {
                    currentBackupsSection(password: nil)
                    hasExistingCodesImportSection
                } else {
                    noExistingCodesImportSection
                }
            case let .fetched(password):
                if dataModel.hasAnyItems {
                    currentBackupsSection(password: password)
                    hasExistingCodesImportSection
                } else {
                    noExistingCodesImportSection
                }
            }
        }
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
                            fileManager: injector.fileManager,
                        ),
                        navigationPath: $pdfNavigationPath,
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
                        deriverFactory: injector.vaultKeyDeriverFactory,
                    ))
                }
            case let .importToCurrentlyEmpty(backupPassword):
                BackupImportFlowView(viewModel: .init(
                    importContext: .toEmptyVault,
                    dataModel: dataModel,
                    existingBackupPassword: backupPassword,
                    encryptedVaultDecoder: injector.encryptedVaultDecoder,
                ))
            case let .importAndMerge(backupPassword):
                BackupImportFlowView(viewModel: .init(
                    importContext: .merge,
                    dataModel: dataModel,
                    existingBackupPassword: backupPassword,
                    encryptedVaultDecoder: injector.encryptedVaultDecoder,
                ))
            case let .importAndOverride(backupPassword):
                BackupImportFlowView(viewModel: .init(
                    importContext: .override,
                    dataModel: dataModel,
                    existingBackupPassword: backupPassword,
                    encryptedVaultDecoder: injector.encryptedVaultDecoder,
                ))
            }
        }
    }

    private func currentBackupsSection(password: DerivedEncryptionKey?) -> some View {
        Section {
            if password != nil {
                LastBackupSummaryView(
                    lastBackup: dataModel.lastBackupEvent,
                )

                updateButton
            } else {
                createButton
            }
        } footer: {
            if let password {
                Button {
                    modal = .pdfBackup(password)
                } label: {
                    Label("Create Backup", systemImage: "printer.filled.and.paper")
                }
                .modifier(ProminentButtonModifier())
                .padding()
                .frame(maxWidth: .infinity)
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
            Text("Backup Encryption Key")
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
                    .backupPasswordErrorDetail : "Authenticate to access backup settings.",
            )
            .padding()
            .containerRelativeFrame(.horizontal)

        } footer: {
            AsyncButton(progressAlignment: .center) {
                await dataModel.loadBackupPassword()
            } label: {
                Label("Authenticate", systemImage: "key.horizontal.fill")
            } loading: {
                ProgressView()
            }
            .modifier(ProminentButtonModifier())
            .containerRelativeFrame(.horizontal)
            .padding()
        }
        .transition(.slide)
    }

    private var createButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            FormRow(image: Image(systemName: "key.horizontal.fill"), color: .accentColor, style: .standard) {
                Text(viewModel.strings.backupPasswordCreateTitle)
            }
        }
    }

    private var updateButton: some View {
        Button {
            modal = .updatePassword
        } label: {
            FormRow(image: Image(systemName: "key.2.on.ring.fill"), color: .accentColor, style: .standard) {
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
                    style: .standard,
                    alignment: .firstTextBaseline,
                ) {
                    TextAndSubtitle(
                        title: "Import Backup",
                        subtitle: "Using a Vault PDF backup file, import data to your device locally.",
                    )
                }
            } loading: {
                ProgressView()
            }
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
                    alignment: .firstTextBaseline,
                ) {
                    TextAndSubtitle(
                        title: "Import & Merge",
                        subtitle: "Recommended. Merges with your existing on-device data. If any items conflict, the most recent version will be used, either from the backup or from your device.",
                    )
                }
            } loading: {
                ProgressView()
            }

            AsyncButton {
                await dataModel.loadBackupPassword()
                modal = .importAndOverride(dataModel.backupPassword.fetchedPassword)
            } label: {
                FormRow(
                    image: Image(systemName: "square.and.arrow.down.fill"),
                    color: .red,
                    style: .standard,
                    alignment: .firstTextBaseline,
                ) {
                    TextAndSubtitle(
                        title: "Import & Override",
                        subtitle: "Warning! Overrides your existing on-device data with the data from the backup. On device data will be replaced by the backup data. If an item exists on device but not in the backup, it will be lost.",
                    )
                }
                .foregroundStyle(.red)
            } loading: {
                ProgressView()
            }
        } header: {
            Text("Import from a backup")
        }
    }
}
