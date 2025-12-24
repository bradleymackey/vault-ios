import Foundation
import SwiftUI
import VaultFeed
import VaultKeygen

@MainActor
struct BackupRestoreView: View {
    @Environment(VaultDataModel.self) var dataModel
    @Environment(VaultInjector.self) var injector
    @State private var viewModel = BackupRestoreViewModel()
    @State private var modal: Modal?

    enum Modal: IdentifiableSelf {
        case importToCurrentlyEmpty(DerivedEncryptionKey?)
        case importAndMerge(DerivedEncryptionKey?)
        case importAndOverride(DerivedEncryptionKey?)
    }

    var body: some View {
        Form {
            if dataModel.hasAnyItems {
                hasExistingCodesImportSection
            } else {
                noExistingCodesImportSection
            }
        }
        .navigationTitle(Text(viewModel.strings.homeTitle))
        .task {
            await dataModel.reloadItems()
        }
        .sheet(item: $modal, onDismiss: nil) { sheet in
            switch sheet {
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
