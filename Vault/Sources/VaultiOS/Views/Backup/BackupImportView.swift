import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportView: View {
    @Environment(VaultDataModel.self) private var dataModel
    @Environment(VaultInjector.self) private var injector

    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case importToCurrentlyEmpty(DerivedEncryptionKey?)
        case importAndMerge(DerivedEncryptionKey?)
        case importAndOverride(DerivedEncryptionKey?)
    }

    var body: some View {
        Form {
            if dataModel.hasAnyItems {
                hasExistingCodesSection
            } else {
                noExistingCodesSection
            }
        }
        .navigationTitle(Text("Restore Backup"))
        .task {
            await dataModel.reloadItems()
        }
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
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

    private var noExistingCodesSection: some View {
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
        }
    }

    private var hasExistingCodesSection: some View {
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
        }
    }
}
