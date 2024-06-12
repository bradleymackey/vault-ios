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
            case .staged:
                confirmImportSection
            case .imported:
                Text("Imported")
            case .error:
                Text("Error")
            }
        }
        .navigationTitle(Text("Import Password"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
        .onReceive(scanner.itemScannedPublisher()) { password in
            viewModel.stageImport(password: password)
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
            Button {
                viewModel.commitStagedImport()
            } label: {
                FormRow(image: Image(systemName: "checkmark"), color: .accentColor) {
                    Text("Confirm Import")
                }
            }
        } header: {
            importWarningView
                .padding(.bottom)
                .frame(maxWidth: .infinity)
        }
    }

    private var importWarningView: some View {
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
