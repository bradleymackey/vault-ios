import Foundation
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct BackupKeyImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BackupKeyImportViewModel
    @State private var scanner = SingleCodeScanner(intervalTimer: LiveIntervalTimer()) { qrCode in
        try BackupPasswordDecoder().decode(qrCode: qrCode)
    }

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(store: store))
    }

    var body: some View {
        Form {
            switch viewModel.importState {
            case .waiting:
                importSection
            case .staged, .imported, .error:
                confirmImportSection
            }
        }
        .navigationTitle(Text("Import Password"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .tint(.red)
                }
            }
        }
        .onReceive(scanner.itemScannedPublisher()) { password in
            viewModel.stageImport(password: password)
        }
        .onChange(of: viewModel.importState) { _, newValue in
            if newValue == .imported {
                dismiss()
            }
        }
    }

    private var importSection: some View {
        Section {
            Text("Scan the code from your other device")
        } header: {
            SingleCodeScannerView(scanner: scanner, isImagePickerVisible: .constant(false))
                .padding()
                .modifier(HorizontallyCenter())
                .onAppear {
                    scanner.startScanning()
                }
                .onDisappear {
                    scanner.disable()
                }
        }
    }

    private var confirmImportSection: some View {
        Section {
            EmptyView()
        } header: {
            switch viewModel.overrideBehaviour {
            case .overridesExisting:
                importOverrideWarningView
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
            case .matchesExisting:
                importMatchesExistingView
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
            case nil:
                importNewView
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
            }
        } footer: {
            VStack(alignment: .center) {
                switch viewModel.overrideBehaviour {
                case .overridesExisting:
                    StandaloneButton {
                        viewModel.commitStagedImport()
                    } content: {
                        Label("Confirm Import", systemImage: "checkmark")
                    }
                case .matchesExisting:
                    EmptyView()
                case nil:
                    StandaloneButton {
                        viewModel.commitStagedImport()
                    } content: {
                        Label("Import", systemImage: "checkmark")
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var importNewView: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                Text("Ready to Import")
            }
            .font(.largeTitle)
            .fontWeight(.medium)
            .foregroundStyle(.green)

            Text("This will set the backup on password on this device to match the other device, so codes can sync.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .textCase(.none)
        }
        .tint(.primary)
        .multilineTextAlignment(.center)
    }

    private var importMatchesExistingView: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                Text("Match")
            }
            .font(.largeTitle)
            .fontWeight(.medium)
            .foregroundStyle(.green)

            Text(
                "This imported password already matches the stored password on this device. There's no need to import it."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .textCase(.none)
        }
        .tint(.primary)
        .multilineTextAlignment(.center)
    }

    private var importOverrideWarningView: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Warning")
            }
            .font(.largeTitle)
            .fontWeight(.heavy)
            .foregroundStyle(.orange)

            Text("This will override your existing password and could affect your current backups.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .textCase(.none)
        }
        .tint(.primary)
        .multilineTextAlignment(.center)
    }
}
