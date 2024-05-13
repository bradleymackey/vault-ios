import CodeScanner
import Foundation
import SwiftUI
import VaultCore
import VaultFeed

struct OTPCodeCreateView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem {
    var feedViewModel: FeedViewModel<Store>
    var previewGenerator: PreviewGenerator

    @State private var isPresentingScanner = false
    @State private var creationMode: CreationMode?

    enum CreationMode: Hashable, Identifiable {
        case manually
        case cameraResult(OTPAuthCode)

        var id: Self { self }
    }

    var body: some View {
        Form {
            Button {
                isPresentingScanner = true
            } label: {
                Text("Camera")
            }

            Button {
                creationMode = .manually
            } label: {
                Text("Enter Code")
            }
        }
        .sheet(isPresented: $isPresentingScanner, onDismiss: nil) {
            codeScanner
        }
        .navigationDestination(item: $creationMode) { newDestination in
            switch newDestination {
            case .manually:
                OTPCodeDetailView(
                    newCodeWithEditor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator
                )
            case let .cameraResult(scannedCode):
                OTPCodeDetailView(
                    newCodeWithEditor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator
                )
            }
        }
    }

    private var codeScanner: some View {
        CodeScannerView(
            codeTypes: [.qr],
            scanMode: .continuous,
            scanInterval: 0.1,
            requiresPhotoOutput: false,
            simulatedData: OTPAuthURI.exampleCodeString,
            shouldVibrateOnSuccess: false
        ) { response in
            if case let .success(result) = response {
                try? decodeOTPAuthURI(string: result.string)
            }
        }
    }

    struct ScanError: Error {}

    private func decodeOTPAuthURI(string: String) throws {
        guard let uri = OTPAuthURI(string: string) else {
            throw ScanError()
        }
        let decoder = OTPAuthURIDecoder()
        let decoded = try decoder.decode(uri: uri)
        isPresentingScanner = false
        creationMode = .cameraResult(decoded)
    }
}
