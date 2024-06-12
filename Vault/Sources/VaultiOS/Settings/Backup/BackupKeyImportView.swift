import Foundation
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
struct BackupKeyImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BackupKeyImportViewModel
    @State private var scanner = SingleCodeScanner(intervalTimer: LiveIntervalTimer()) { string in
        if let data = string.data(using: .utf8) {
            return data
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        }
    }

    init(store: any BackupPasswordStore) {
        _viewModel = .init(initialValue: .init(importer: BackupPasswordImporterImpl(store: store)))
    }

    var body: some View {
        Form {
            importSection
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
        .onAppear {
            scanner.startScanning()
        }
        .onDisappear {
            scanner.disable()
        }
        .onReceive(scanner.itemScannedPublisher()) { _ in
            // TODO: use scanned imported data
        }
    }

    private var importSection: some View {
        Section {
            Text("Scan the code from your other device")
        } header: {
            SingleCodeScannerView(scanner: scanner, isImagePickerVisible: .constant(false))
                .padding()
                .modifier(HorizontallyCenter())
        }
    }
}
