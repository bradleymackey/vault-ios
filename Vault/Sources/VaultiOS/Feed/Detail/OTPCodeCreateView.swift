import CodeScanner
import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

struct OTPCodeCreateView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem {
    var feedViewModel: FeedViewModel<Store>
    var previewGenerator: PreviewGenerator

    @Environment(\.dismiss) private var dismiss
    @State private var creationMode: CreationMode?

    enum CreationMode: Hashable, IdentifiableSelf {
        case manually
        case cameraResult(OTPAuthCode)
    }

    var body: some View {
        Form {
            section
        }
        .navigationTitle(Text("Scan Code"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationDestination(item: $creationMode) { newDestination in
            switch newDestination {
            case .manually:
                OTPCodeDetailView(
                    newCodeWithContext: nil,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator
                )
            case let .cameraResult(scannedCode):
                OTPCodeDetailView(
                    newCodeWithContext: scannedCode,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator
                )
            }
        }
    }

    private var section: some View {
        Section {
            Button {
                creationMode = .manually
            } label: {
                Text("Enter Key Manually")
            }
        } header: {
            scannerViewWindow
                .aspectRatio(1, contentMode: .fill)
                .frame(minWidth: 150, maxWidth: 250, minHeight: 150, maxHeight: 250, alignment: .center)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10), style: .continuous))
                .padding()
                .modifier(HorizontallyCenter())
        }
    }

    private var scannerViewWindow: some View {
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
        #if targetEnvironment(simulator)
        .background(
            LinearGradient(colors: [.red, .blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
                .saturation(0.8)
                .opacity(0.4)
        )
        #endif
    }

    struct ScanError: Error {}

    private func decodeOTPAuthURI(string: String) throws {
        guard let uri = OTPAuthURI(string: string) else {
            throw ScanError()
        }
        let decoder = OTPAuthURIDecoder()
        let decoded = try decoder.decode(uri: uri)
        creationMode = .cameraResult(decoded)
    }
}
