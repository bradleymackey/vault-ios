import Foundation
import SwiftUI
import VaultFeed
import VaultKeygen

@MainActor
struct BackupCreateView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(DeviceAuthenticationService.self) var authenticationService
    @Environment(VaultInjector.self) var injector
    @State private var viewModel = BackupCreateViewModel()
    @State private var modal: Modal?
    @State private var pdfNavigationPath = NavigationPath()

    enum Modal: IdentifiableSelf {
        case updatePassword
        case pdfBackup(DerivedEncryptionKey)
    }

    var body: some View {
        Form {
            switch dataModel.backupPassword {
            case .error:
                authenticateSection(isError: true)
            case .notFetched:
                authenticateSection(isError: false)
            case .notCreated:
                currentBackupsSection(password: nil)
            case let .fetched(password):
                currentBackupsSection(password: password)
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
}
