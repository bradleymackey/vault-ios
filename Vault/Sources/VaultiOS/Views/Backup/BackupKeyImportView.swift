import Foundation
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
struct BackupKeyImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BackupKeyImportViewModel
    @State private var scanner = SingleCodeScanner(intervalTimer: IntervalTimerImpl()) { qrCode in
        try BackupPasswordDecoder().decode(qrCode: qrCode)
    }

    init(viewModel: BackupKeyImportViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
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
        .navigationTitle(Text("Import Key"))
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
            Task {
                await viewModel.stageImport(password: password)
            }
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
                    AsyncButton {
                        await viewModel.commitStagedImport()
                    } label: {
                        Label("Confirm Import", systemImage: "checkmark")
                    }
                    .modifier(ProminentButtonModifier())
                case .matchesExisting:
                    EmptyView()
                case nil:
                    AsyncButton {
                        await viewModel.commitStagedImport()
                    } label: {
                        Label("Import", systemImage: "checkmark")
                    }
                    .modifier(ProminentButtonModifier())
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
