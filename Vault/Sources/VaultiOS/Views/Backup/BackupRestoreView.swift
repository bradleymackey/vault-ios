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
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                if dataModel.hasAnyItems {
                    hasExistingCodesImportCards
                } else {
                    noExistingCodesImportCard
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
}

// MARK: - BackupRestoreView Extensions

extension BackupRestoreView {
    private var noExistingCodesImportCard: some View {
        ImportOptionCard(
            icon: "square.and.arrow.down.fill",
            iconColor: .accentColor,
            title: "Import Backup",
            subtitle: "Import data from a Vault backup using a PDF file or by scanning QR codes from another device.",
            buttonLabel: "Import Backup",
            buttonIcon: "square.and.arrow.down.fill",
            isDestructive: false,
            showRecommended: false,
        ) {
            await dataModel.loadBackupPassword()
            modal = .importToCurrentlyEmpty(dataModel.backupPassword.fetchedPassword)
        }
    }

    private var hasExistingCodesImportCards: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Import from a backup")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 4)

            // Merge option (recommended)
            ImportOptionCard(
                icon: "square.and.arrow.down.on.square.fill",
                iconColor: .accentColor,
                title: "Import & Merge",
                subtitle: "Import from a PDF file or scan QR codes from another device. Merges with existing data, keeping the most recent version of each item.",
                buttonLabel: "Import & Merge",
                buttonIcon: "square.and.arrow.down.on.square.fill",
                isDestructive: false,
                showRecommended: true,
            ) {
                await dataModel.loadBackupPassword()
                modal = .importAndMerge(dataModel.backupPassword.fetchedPassword)
            }

            // Override option (destructive)
            ImportOptionCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Import & Override",
                subtitle: "⚠️ Warning! Import from a PDF file or scan QR codes and replace all existing data. On-device data will be lost if not in the backup.",
                buttonLabel: "Import & Override",
                buttonIcon: "square.and.arrow.down.fill",
                isDestructive: true,
                showRecommended: false,
            ) {
                await dataModel.loadBackupPassword()
                modal = .importAndOverride(dataModel.backupPassword.fetchedPassword)
            }
        }
    }
}

// MARK: - Import Option Card Component

private struct ImportOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let buttonLabel: String
    let buttonIcon: String
    let isDestructive: Bool
    let showRecommended: Bool
    let action: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Spacer()

                if showRecommended {
                    Text("Recommended")
                        .textCase(.uppercase)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            // Description
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Action button
            AsyncButton {
                await action()
            } label: {
                Label(buttonLabel, systemImage: buttonIcon)
                    .frame(maxWidth: .infinity)
            } loading: {
                ProgressView()
                    .tint(.white)
            }
            .modifier(ProminentButtonModifier(
                color: isDestructive ? .red : .accentColor,
            ))
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: isDestructive ? .red : .accentColor,
            padding: .init(),
        )))
    }
}
