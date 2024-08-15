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
                    // FIXME: use the actual key
                    BackupCreatePDFView(viewModel: .init(
                        backupExporter: .init(
                            clock: clock,
                            backupPassword: .init(
                                key: Data.random(count: 32),
                                salt: Data.random(count: 32),
                                keyDervier: .fastV1
                            )
                        ),
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
            case .exportPassword:
                NavigationStack {
                    BackupKeyExportView(viewModel: .init(exporter: .init(dataModel: dataModel)))
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
            switch dataModel.backupPassword {
            case .notFetched:
                PlaceholderView(systemIcon: "lock.fill", title: viewModel.strings.backupPasswordLoadingTitle)
                    .foregroundStyle(.secondary)
                    .padding()
                    .containerRelativeFrame(.horizontal)
            case .fetched:
                updateButton
                exportButton
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
