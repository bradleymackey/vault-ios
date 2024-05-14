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
    @Binding var navigationPath: NavigationPath

    // Using 'dismiss' causes a hang here!
    //
    // This was the cause of a very strange bug that caused an infinite hang on trying to
    // present the next OTP code detail editing view.
    //
    // Checking the SwiftUI update profiler, there was an infinite loop being caused (for some reason)
    // because the `@Environment(\.dismiss)` trigger was recursively called between this view and
    // other views that get pushed that also used the same environment variable.
    @Environment(\.presentationMode) private var presentationMode
    @State private var isCodeImagePickerGalleryVisible = false
    @State private var isScannerActive = false

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
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut) {
                isScannerActive = true
            }
        }
        .onDisappear {
            isScannerActive = false
        }
        .navigationDestination(for: CreationMode.self, destination: { newDestination in
            switch newDestination {
            case .manually:
                OTPCodeDetailView(
                    newCodeWithContext: nil,
                    navigationPath: $navigationPath,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator
                )
            case let .cameraResult(scannedCode):
                OTPCodeDetailView(
                    newCodeWithContext: scannedCode,
                    navigationPath: $navigationPath,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator
                )
            }
        })
    }

    private var section: some View {
        Section {
            Button {
                isCodeImagePickerGalleryVisible = true
            } label: {
                Text("Pick image from photos")
            }

            NavigationLink("Enter Key Manually", value: CreationMode.manually)
        } header: {
            scanningView
                .aspectRatio(1, contentMode: .fill)
                .frame(minWidth: 150, maxWidth: 250, minHeight: 150, maxHeight: 250, alignment: .center)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10), style: .continuous))
                .padding()
                .modifier(HorizontallyCenter())
        }
    }

    @ViewBuilder
    private var scanningView: some View {
        if isScannerActive {
            scannerViewWindow
                .transition(.blurReplace)
        } else {
            Color.black
                .transition(.blurReplace)
                .onTapGesture {
                    isScannerActive = true
                }
        }
    }

    private var scannerViewWindow: some View {
        CodeScannerView(
            codeTypes: [.qr],
            scanMode: .continuous,
            scanInterval: 0.1,
            showViewfinder: false,
            requiresPhotoOutput: false,
            simulatedData: OTPAuthURI.exampleCodeString,
            shouldVibrateOnSuccess: false,
            isPaused: !isScannerActive,
            isGalleryPresented: $isCodeImagePickerGalleryVisible
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
        isScannerActive = false
        navigationPath.append(CreationMode.cameraResult(decoded))
    }
}
