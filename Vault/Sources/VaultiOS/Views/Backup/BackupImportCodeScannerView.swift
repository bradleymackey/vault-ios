import CodeScanner
import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct BackupImportCodeScannerView: View {
    @State private var scanner: CodeScanningManager<BackupImportScanningHandler>
    @Environment(\.presentationMode) private var presentationMode
    @State private var isCodeImagePickerGalleryVisible = false
    @State private var handler: BackupImportScanningHandler

    init(intervalTimer: any IntervalTimer) {
        let handler = BackupImportScanningHandler()
        scanner = CodeScanningManager(intervalTimer: intervalTimer, handler: handler)
        self.handler = handler
    }

    var body: some View {
        Form {
            section
        }
        .navigationTitle(Text("Import Vault"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            scanner.startScanning()
        }
        .onDisappear {
            scanner.disable()
        }
        .onReceive(scanner.itemScannedPublisher()) { encryptedVault in
            print("Scanned vault", encryptedVault)
        }
    }

    private var section: some View {
        Section {
            if let remainingShards = handler.remainingShards {
                Text("Remaining \(remainingShards)")
            } else {
                Text("Scan a code to start")
            }
        } header: {
            CodeScanningView(scanner: scanner, isImagePickerVisible: $isCodeImagePickerGalleryVisible)
                .padding()
                .modifier(HorizontallyCenter())
        }
    }
}
