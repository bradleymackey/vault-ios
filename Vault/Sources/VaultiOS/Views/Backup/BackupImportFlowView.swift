import Combine
import Foundation
import FoundationExtensions
import SwiftUI
import VaultBackup
import VaultFeed

@MainActor
struct BackupImportFlowView: View {
    @Environment(VaultInjector.self) private var injector
    @State private var viewModel: BackupImportFlowViewModel
    @State private var isImporting = false
    @State private var importTask: Task<Void, any Error>?
    @State private var navPath = NavigationPath()
    @State private var modal: Modal?
    @State private var decryptedVaultSubject = PassthroughSubject<VaultApplicationPayload, Never>()

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BackupImportFlowViewModel) {
        self.viewModel = viewModel
    }

    private enum Modal: IdentifiableSelf {
        case generateDecryptionKey(EncryptedVault)
        case cameraScanning
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            rootContent
        }
        .interactiveDismissDisabled(!viewModel.importState.isFinished)
        .sheet(item: $modal, onDismiss: nil) { item in
            switch item {
            case let .generateDecryptionKey(encryptedVault):
                NavigationStack {
                    BackupKeyDecryptorView(viewModel: .init(
                        encryptedVault: encryptedVault,
                        keyDeriverFactory: injector.vaultKeyDeriverFactory,
                        encryptedVaultDecoder: injector.encryptedVaultDecoder,
                        decryptedVaultSubject: decryptedVaultSubject,
                    ))
                    .navigationBarTitleDisplayMode(.inline)
                }
            case .cameraScanning:
                NavigationStack {
                    BackupImportCodeScannerView(
                        intervalTimer: injector.intervalTimer,
                        loadedEncryptedVault: {
                            modal = nil
                            await viewModel.handleImport(fromEncryptedVault: $0)
                        },
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onReceive(decryptedVaultSubject) { @MainActor vaultApplicationPayload in
            viewModel.handleVaultDecoded(payload: vaultApplicationPayload)
        }
        .onChange(of: viewModel.payloadState) { _, newValue in
            switch newValue {
            case let .ready(payload, _):
                navPath.append(payload)
            case .none, .error, .needsPasswordEntry:
                break
            }
        }
    }

    private var rootContent: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                switch viewModel.payloadState {
                case .none, .ready:
                    EmptyView()
                case let .needsPasswordEntry(vault):
                    passwordNeededCard(vault: vault)
                case let .error(presentationError):
                    errorCard(error: presentationError)
                }

                filePickerCards
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .foregroundStyle(Color.red)
            }
        }
        .animation(.easeOut, value: viewModel.importState)
        .animation(.easeOut, value: viewModel.payloadState)
        .navigationTitle(Text("Import"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: VaultApplicationPayload.self) { payload in
            readyToImportView(vaultApplicationPayload: payload)
        }
    }

    // MARK: - Password Needed Card

    private func passwordNeededCard(vault: EncryptedVault) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "lock.badge.clock.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Decryption Password Needed")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text("You need to enter the password that was used to encrypt this export.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                modal = .generateDecryptionKey(vault)
            } label: {
                Label("Enter Password", systemImage: "square.and.pencil")
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
    }

    // MARK: - Error Card

    private func errorCard(error: PresentationError) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.red)
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.userTitle)
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    if let description = error.userDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.red,
            padding: .init(),
        )))
    }

    // MARK: - File Picker Cards

    private var filePickerCards: some View {
        VStack(spacing: 16) {
            // Automatic Import Card
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.document.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Automatic Import")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Spacer()
                }

                Text("Select your Vault Export PDF from your files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    isImporting = true
                } label: {
                    Label("Select PDF File", systemImage: "arrow.down.document.fill")
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
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
                importTask = Task {
                    await viewModel.handleImport(fromPDF: result.tryMap { url in
                        _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        return try Data(contentsOf: url)
                    })
                }
            }

            // Manual Import Card
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Manual Import")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Spacer()
                }

                Text("Use your camera to scan all the QR codes on your Vault Export document")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    modal = .cameraScanning
                } label: {
                    Label("Scan QR Codes", systemImage: "qrcode.viewfinder")
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
        }
    }

    // MARK: - Ready to Import View

    private func readyToImportView(vaultApplicationPayload: VaultApplicationPayload) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                switch viewModel.importState {
                case .notStarted:
                    readyToImportCard(payload: vaultApplicationPayload)
                case let .error(error):
                    importErrorCard(error: error)
                    importButton(vault: vaultApplicationPayload)
                case .success:
                    successCard
                }
            }
            .padding(16)
        }
        .animation(.easeOut, value: viewModel.importState)
        .animation(.easeOut, value: viewModel.payloadState)
        .toolbar {
            if viewModel.importState.isFinished {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }

    // MARK: - Ready to Import Card

    private func readyToImportCard(payload: VaultApplicationPayload) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.importContext.readyToImportTitle)
                            .font(.headline.bold())
                            .foregroundStyle(.primary)

                        Text(viewModel.importContext.readyToImportDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .modifier(VaultCardModifier(configuration: .init(
                style: .secondary,
                border: Color.accentColor,
                padding: .init(),
            )))

            importButton(vault: payload)
        }
    }

    // MARK: - Import Error Card

    private func importErrorCard(error: PresentationError) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.red)
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.userTitle)
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    if let description = error.userDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.red,
            padding: .init(),
        )))
    }

    // MARK: - Success Card

    private var successCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.green)
                    .frame(width: 40, height: 40)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Imported")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)

                    Text("Your vault has been updated with the items from this backup.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .modifier(VaultCardModifier(configuration: .init(
            style: .secondary,
            border: Color.green,
            padding: .init(),
        )))
    }

    // MARK: - Import Button

    private func importButton(vault: VaultApplicationPayload) -> some View {
        AsyncButton {
            await viewModel.importPayload(payload: vault)
        } label: {
            Label("Import Now", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        } loading: {
            ProgressView()
                .tint(.white)
        }
        .modifier(ProminentButtonModifier())
    }
}
