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
        case deviceTransfer(DerivedEncryptionKey)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                switch dataModel.backupPassword {
                case .error:
                    authenticateCard(isError: true)
                case .notFetched:
                    authenticateCard(isError: false)
                case .notCreated:
                    passwordNotCreatedCard
                case let .fetched(password):
                    passwordExistsCard
                    lastBackupSummaryCard(password: password)
                    deviceTransferCard(password: password)
                }
            }
            .padding(16)
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
            case let .deviceTransfer(password):
                NavigationStack {
                    DeviceTransferExportView(
                        viewModel: .init(
                            backupPassword: password,
                            dataModel: dataModel,
                            clock: injector.clock,
                            backupEventLogger: injector.backupEventLogger,
                            intervalTimer: injector.intervalTimer,
                        ),
                    )
                }
            }
        }
    }

    // MARK: - Authenticate Card

    private func authenticateCard(isError: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            PlaceholderView(
                systemIcon: isError ? "key.slash.fill" : "lock.fill",
                title: isError ? viewModel.strings.backupPasswordErrorTitle : viewModel.strings
                    .backupPasswordLoadingTitle,
                subtitle: isError ? viewModel.strings
                    .backupPasswordErrorDetail : "Authenticate to access backup settings.",
            )

            AsyncButton(progressAlignment: .center) {
                await dataModel.loadBackupPassword()
            } label: {
                Label("Authenticate", systemImage: "key.horizontal.fill")
                    .frame(maxWidth: .infinity)
            } loading: {
                ProgressView()
                    .tint(.white)
            }
            .modifier(ProminentButtonModifier())
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: isError ? .red : .accentColor,
            padding: .init(),
        )))
        .transition(.slide)
    }

    // MARK: - Password Not Created Card

    private var passwordNotCreatedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "key.horizontal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Backup Password Not Set")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text("Create a backup password to protect your vault backups.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                modal = .updatePassword
            } label: {
                Label("Create Backup Password", systemImage: "key.horizontal.fill")
                    .frame(maxWidth: .infinity)
            }
            .modifier(ProminentButtonModifier())
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.accentColor,
            padding: .init(),
        )))
        .transition(.slide)
    }

    // MARK: - Password Exists Card

    private var passwordExistsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.green)
                    .frame(width: 40, height: 40)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Backup Password Active")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text("Your backups are protected with encryption.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button {
                modal = .updatePassword
            } label: {
                Label("Change Password", systemImage: "key.2.on.ring.fill")
                    .frame(maxWidth: .infinity)
            }
            .modifier(ProminentButtonModifier(color: .gray))
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.green,
            padding: .init(),
        )))
        .transition(.slide)
    }

    // MARK: - Last Backup Summary Card

    private func lastBackupSummaryCard(password: DerivedEncryptionKey) -> some View {
        VStack(spacing: 0) {
            LastBackupSummaryView(
                lastBackup: dataModel.lastBackupEvent,
            )

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                Button {
                    modal = .pdfBackup(password)
                } label: {
                    Label("Create PDF Backup", systemImage: "printer.filled.and.paper")
                        .frame(maxWidth: .infinity)
                }
                .modifier(ProminentButtonModifier())
            }
            .padding(16)
        }
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: lastBackupBorderColor,
            padding: .init(),
        )))
        .transition(.slide)
    }

    private var lastBackupBorderColor: Color {
        guard let lastBackup = dataModel.lastBackupEvent else { return Color.red }

        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackup.backupDate, to: Date())
            .day ?? Int.max

        if daysSinceBackup < 7 {
            return Color.green
        } else if daysSinceBackup < 30 {
            return Color.orange
        } else {
            return Color.red
        }
    }

    // MARK: - Device Transfer Card

    private func deviceTransferCard(password: DerivedEncryptionKey) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Transfer to Another Device")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text("Display QR codes to scan with another device.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button {
                modal = .deviceTransfer(password)
            } label: {
                Label("Start Transfer", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .modifier(ProminentButtonModifier())
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.accentColor,
            padding: .init(),
        )))
        .transition(.slide)
    }
}
