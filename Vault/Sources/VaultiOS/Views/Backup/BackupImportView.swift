import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportView: View {
    @Environment(VaultDataModel.self) private var dataModel

    @State private var modal: Modal?

    private enum Modal: IdentifiableSelf {
        case importToCurrentlyEmpty(BackupPassword?)
        case importAndMerge(BackupPassword?)
        case importAndOverride(BackupPassword?)
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
                NavigationStack {
                    BackupImportFlowView(viewModel: .init(
                        importContext: .toEmptyVault,
                        existingBackupPassword: backupPassword
                    ))
                }
            case let .importAndMerge(backupPassword):
                NavigationStack {
                    BackupImportFlowView(viewModel: .init(
                        importContext: .merge,
                        existingBackupPassword: backupPassword
                    ))
                }
            case let .importAndOverride(backupPassword):
                NavigationStack {
                    BackupImportFlowView(viewModel: .init(
                        importContext: .override,
                        existingBackupPassword: backupPassword
                    ))
                }
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
