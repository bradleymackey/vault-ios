import CodeScanner
import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct CodeScanningView<Handler: CodeScanningHandler>: View {
    @State var scanner: CodeScanningManager<Handler>
    @Binding var isImagePickerVisible: Bool
    @State private var isCameraError = false

    var body: some View {
        scanningView
            .aspectRatio(1, contentMode: .fill)
            .frame(minWidth: 150, maxWidth: 250, minHeight: 150, maxHeight: 250, alignment: .center)
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10), style: .continuous))
    }

    @ViewBuilder
    private var scanningView: some View {
        if isCameraError {
            cameraErrorView
        } else {
            switch scanner.scanningState {
            case .disabled:
                scanningDisabledView
            case .failure(.unrecoverable):
                scanningUnrecoverableErrorView
            case .scanning, .failure(.temporary), .success:
                scannerView
            }
        }
    }

    private var scannerView: some View {
        ZStack {
            scannerViewWindow

            switch scanner.scanningState {
            case .failure(.temporary):
                scanningFailedView
            case .success(.temporary):
                scanningTemporarySuccessView
            case .success(.complete):
                scanningCompleteSuccessView
            default:
                EmptyView()
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

    private var scanningCompleteSuccessView: some View {
        ZStack {
            Color.green
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle.bold())
                Text("Success")
                    .font(.callout.bold())
                    .textCase(.uppercase)
            }
            .foregroundStyle(.white)
        }
    }

    private var scanningTemporarySuccessView: some View {
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

    private var scanningUnrecoverableErrorView: some View {
        ZStack {
            Color.red
            VStack(spacing: 8) {
                Image(systemName: "xmark.diamond.fill")
                    .font(.largeTitle.bold())
                VStack {
                    Text("Invalid Data")
                        .fontWeight(.bold)
                    Text("Please try again")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
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
                    Text("Camera Error")
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                    Text("Check your device and permissions")
                }
                .font(.callout)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding()
        }
    }

    private var scannerViewWindow: some View {
        CodeScannerView(
            codeTypes: [.qr],
            scanMode: .continuous,
            scanInterval: 2.0,
            showViewfinder: false,
            requiresPhotoOutput: false,
            simulatedData: VaultIdentifiers.CodeScanning.simulatedCode,
            shouldVibrateOnSuccess: false,
            isPaused: scanner.scanningState.pausesCamera,
            isGalleryPresented: $isImagePickerVisible,
        ) { response in
            do {
                let result = try response.get()
                if result.string == VaultIdentifiers.CodeScanning.simulatedCode {
                    scanner.simulatedScan()
                } else {
                    scanner.scan(text: result.string)
                }
            } catch {
                isCameraError = true
            }
        }
        #if targetEnvironment(simulator)
        .background(
            LinearGradient(colors: [.red, .blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
                .saturation(0.8)
                .opacity(0.4),
        )
        #endif
    }
}

extension CodeScanningState {
    fileprivate var pausesCamera: Bool {
        switch self {
        case .disabled, .success, .failure: true
        case .scanning: false
        }
    }
}
