import Foundation
import SwiftUI
import UniformTypeIdentifiers
import VaultFeed

/// View for configuring and monitoring auto-backup settings.
@MainActor
struct AutoBackupSettingsView: View {
    @Environment(VaultInjector.self) var injector
    let autoBackupService: any AutoBackupService

    @State private var isShowingFolderPicker = false
    @State private var selectedProviderID: String?
    @State private var providerConfigStates: [String: Bool] = [:]

    // Local state to observe changes from publishers
    @State private var status: AutoBackupStatus = .disabled
    @State private var configuration: AutoBackupConfiguration = .init()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView

            if configuration.isEnabled {
                enabledContentView
            } else {
                disabledContentView
            }
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: borderColor,
            padding: .init(),
        )))
        .sheet(isPresented: $isShowingFolderPicker) {
            FolderPickerView { url in
                configureSelectedProvider(with: url)
            }
        }
        .task {
            // Initialize with current values
            status = autoBackupService.status
            configuration = autoBackupService.configuration
            await loadProviderConfigStates()
        }
        .onReceive(autoBackupService.statusPublisher) { newStatus in
            status = newStatus
        }
        .onReceive(autoBackupService.configurationPublisher) { newConfiguration in
            configuration = newConfiguration
            // Refresh provider states when configuration changes
            Task {
                await loadProviderConfigStates()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIconName)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 40, height: 40)
                .background(statusColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Auto-Backup")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text(statusDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { configuration.isEnabled },
                set: { enabled in
                    Task {
                        await autoBackupService.setEnabled(enabled)
                    }
                },
            ))
            .labelsHidden()
        }
    }

    // MARK: - Enabled Content

    private var enabledContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            providerSelectionView

            if configuration.providerID != nil {
                retentionPickerView
            }

            if case let .error(error) = status {
                errorView(error)
            }

            actionButtonsView
        }
    }

    private var providerSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Destination")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(autoBackupService.availableProviders, id: \.id) { provider in
                providerRow(provider, isConfigured: providerConfigStates[provider.id] ?? false)
            }
        }
    }

    private func providerRow(_ provider: any BackupStorageProvider, isConfigured: Bool) -> some View {
        let isSelected = configuration.providerID == provider.id

        return Button {
            Task {
                await autoBackupService.selectProvider(id: provider.id)
                // Show folder picker if not configured, or if already selected (to allow reconfiguring)
                if !isConfigured || isSelected {
                    isShowingFolderPicker = true
                    selectedProviderID = provider.id
                }
            }
        } label: {
            HStack {
                Image(systemName: provider.iconSystemName)
                    .foregroundStyle(isSelected ? .white : .green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .foregroundStyle(isSelected ? .white : .primary)

                    if isConfigured {
                        Text("Configured")
                            .font(.caption)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    } else {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                } else if isConfigured {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.green : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1),
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var retentionPickerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keep backups for")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Retention", selection: Binding(
                get: { configuration.retentionDays },
                set: { retention in
                    Task {
                        await autoBackupService.setRetention(retention)
                    }
                },
            )) {
                ForEach(AutoBackupRetention.allCases, id: \.self) { retention in
                    Text(retention.localizedTitle).tag(retention)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func errorView(_ error: AutoBackupError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.callout)
                    .foregroundStyle(.primary)

                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            if let providerID = configuration.providerID,
               let provider = autoBackupService.availableProviders.first(where: { $0.id == providerID })
            {
                let isConfigured = providerConfigStates[provider.id] ?? false
                if isConfigured {
                    AsyncButton(progressAlignment: .center) {
                        await autoBackupService.forceBackup()
                    } label: {
                        Label("Backup Now", systemImage: "arrow.clockwise.icloud")
                            .frame(maxWidth: .infinity)
                    } loading: {
                        ProgressView()
                            .tint(.white)
                    }
                    .modifier(ProminentButtonModifier())
                    .disabled(isBackingUp)
                } else {
                    Button {
                        selectedProviderID = provider.id
                        isShowingFolderPicker = true
                    } label: {
                        Label("Select Folder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .modifier(ProminentButtonModifier())
                }
            }
        }
    }

    // MARK: - Disabled Content

    private var disabledContentView: some View {
        Text("Enable to automatically back up your vault to cloud storage whenever changes are made.")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private var borderColor: Color {
        switch status {
        case .disabled:
            .gray
        case .idle, .completed:
            .green
        case .backingUp, .cleaningUp:
            .accentColor
        case .error:
            .orange
        }
    }

    private var statusColor: Color {
        switch status {
        case .disabled:
            .gray
        case .idle, .completed:
            .green
        case .backingUp, .cleaningUp:
            .accentColor
        case .error:
            .orange
        }
    }

    private var statusIconName: String {
        switch status {
        case .disabled:
            "icloud.slash"
        case .idle:
            "icloud"
        case .backingUp, .cleaningUp:
            "arrow.clockwise.icloud"
        case .completed:
            "checkmark.icloud"
        case .error:
            "exclamationmark.icloud"
        }
    }

    private var statusDescription: String {
        switch status {
        case .disabled:
            "Automatic backups are disabled"
        case .idle:
            "Ready to back up when changes occur"
        case .backingUp:
            "Backing up..."
        case .cleaningUp:
            "Cleaning up old backups..."
        case let .completed(date):
            "Last backup: \(date.formatted(date: .abbreviated, time: .shortened))"
        case .error:
            "Backup failed"
        }
    }

    private var isBackingUp: Bool {
        if case .backingUp = status { return true }
        if case .cleaningUp = status { return true }
        return false
    }

    private func loadProviderConfigStates() async {
        for provider in autoBackupService.availableProviders {
            providerConfigStates[provider.id] = await provider.isConfigured
        }
    }

    private func configureSelectedProvider(with url: URL) {
        guard let providerID = selectedProviderID,
              let provider = autoBackupService.availableProviders.first(where: { $0.id == providerID })
        else { return }

        if let iCloudProvider = provider as? iCloudDriveProvider {
            Task {
                do {
                    try await iCloudProvider.configure(with: url)
                    // Save the configuration to persistent storage
                    await autoBackupService.saveProviderConfiguration()
                    await loadProviderConfigStates()
                    // Trigger a backup now that it's configured
                    await autoBackupService.triggerBackupIfNeeded()
                } catch {
                    // Configuration failed - the provider will remain unconfigured
                }
            }
        }
    }
}

// MARK: - Folder Picker

private struct FolderPickerView: UIViewControllerRepresentable {
    let onFolderSelected: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFolderSelected: onFolderSelected)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFolderSelected: (URL) -> Void

        init(onFolderSelected: @escaping (URL) -> Void) {
            self.onFolderSelected = onFolderSelected
        }

        func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onFolderSelected(url)
        }
    }
}
