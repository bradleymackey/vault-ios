import CodeScanner
import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed
import VaultUI

@MainActor
struct OTPCodeCreateView<
    Store: VaultStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem {
    var feedViewModel: FeedViewModel<Store>
    var previewGenerator: PreviewGenerator
    @Binding var navigationPath: NavigationPath

    // Using 'dismiss' here and in a child will cause a hang here!
    //
    // This was the cause of a very strange bug that caused an infinite hang on trying to
    // present the next OTP code detail editing view.
    //
    // Checking the SwiftUI update profiler, there was an infinite loop being caused (for some reason)
    // because the `@Environment(\.dismiss)` trigger was recursively called between this view and
    // other views that get pushed that also used the same environment variable.

    // 'dismiss' applies in the context that it's defined in!
    @Environment(\.presentationMode) private var presentationMode
    @State private var isCodeImagePickerGalleryVisible = false
    @State private var scanner = OTPCodeScanner(intervalTimer: LiveIntervalTimer())
    @State private var isCameraError = false

    enum CreationMode: Hashable, IdentifiableSelf {
        case manually
        case cameraResult(OTPAuthCode)
    }

    var body: some View {
        Form {
            section
        }
        .navigationTitle(Text(feedViewModel.scanCodeTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(feedViewModel.cancelEditsTitle)
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
        .onReceive(scanner.navigateToScannedCodePublisher(), perform: { scannedCode in
            navigationPath.append(CreationMode.cameraResult(scannedCode))
        })
        .navigationDestination(for: CreationMode.self, destination: { newDestination in
            switch newDestination {
            case .manually:
                OTPCodeDetailView(
                    newCodeWithContext: nil,
                    navigationPath: $navigationPath,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator,
                    presentationMode: presentationMode
                )
            case let .cameraResult(scannedCode):
                OTPCodeDetailView(
                    newCodeWithContext: scannedCode,
                    navigationPath: $navigationPath,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator,
                    presentationMode: presentationMode
                )
            }
        })
    }

    private var section: some View {
        Section {
            Button {
                isCodeImagePickerGalleryVisible = true
            } label: {
                Label(feedViewModel.inputSelectImageFromLibraryTitle, systemImage: "qrcode.viewfinder")
            }
            .foregroundStyle(.primary)

            NavigationLink(value: CreationMode.manually) {
                Label(feedViewModel.inputEnterCodeManuallyTitle, systemImage: "entry.lever.keypad")
            }
            .foregroundStyle(.primary)
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
        if isCameraError {
            cameraErrorView
        } else {
            switch scanner.scanningState {
            case .disabled:
                scanningDisabledView
            case .scanning, .invalidCodeScanned:
                scannerView
            case .success:
                scanningSuccessView
            }
        }
    }

    private var scanningDisabledView: some View {
        ZStack {
            Color.black
            Image(systemName: "camera.fill")
                .foregroundStyle(.white)
                .font(.largeTitle.bold())
        }
        .onTapGesture {
            scanner.startScanning()
        }
    }

    private var scanningSuccessView: some View {
        ZStack {
            Color.green
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
                .font(.largeTitle.bold())
        }
    }

    private var scanningFailedView: some View {
        ZStack {
            Color.red
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle.bold())
                Text("Invalid Code")
                    .font(.callout.bold())
                    .textCase(.uppercase)
            }
            .foregroundStyle(.white)
        }
    }

    private var cameraErrorView: some View {
        ZStack {
            Color.red
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle.bold())
                VStack(spacing: 4) {
                    Text(feedViewModel.cameraErrorTitle)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                    Text(feedViewModel.cameraErrorDescription)
                }
                .font(.callout)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding()
        }
    }

    private var scannerView: some View {
        ZStack {
            scannerViewWindow

            if scanner.scanningState == .invalidCodeScanned {
                scanningFailedView
            }
        }
    }

    private var scannerViewWindow: some View {
        CodeScannerView(
            codeTypes: [.qr],
            scanMode: .continuous,
            scanInterval: 2.0,
            showViewfinder: false,
            requiresPhotoOutput: false,
            simulatedData: OTPAuthURI.exampleCodeString,
            shouldVibrateOnSuccess: false,
            isPaused: scanner.scanningState.pausesCamera,
            isGalleryPresented: $isCodeImagePickerGalleryVisible
        ) { response in
            do {
                let result = try response.get()
                scanner.scan(text: result.string)
            } catch {
                isCameraError = true
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
}

extension OTPCodeScanningState {
    fileprivate var pausesCamera: Bool {
        switch self {
        case .disabled, .success, .invalidCodeScanned: true
        case .scanning: false
        }
    }
}
