import CodeScanner
import Foundation
import FoundationExtensions
import SwiftUI
import VaultCore
import VaultFeed

@MainActor
struct OTPCodeCreateView<
    Store: VaultStore & VaultTagStore,
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem.Payload {
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
    @Environment(VaultDataModel.self) private var dataModel
    @State private var isCodeImagePickerGalleryVisible = false
    @State private var scanner = SingleCodeScanner(intervalTimer: IntervalTimerImpl()) { string in
        guard let uri = OTPAuthURI(string: string) else {
            throw URLError(.badURL)
        }
        return try OTPAuthURIDecoder().decode(uri: uri)
    }

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
        .onReceive(scanner.itemScannedPublisher()) { scannedCode in
            navigationPath.append(CreationMode.cameraResult(scannedCode))
        }
        .navigationDestination(for: CreationMode.self, destination: { newDestination in
            switch newDestination {
            case .manually:
                OTPCodeDetailView(
                    newCodeWithContext: nil,
                    navigationPath: $navigationPath,
                    dataModel: dataModel,
                    editor: VaultFeedDetailEditorAdapter(vaultFeed: feedViewModel),
                    previewGenerator: previewGenerator,
                    presentationMode: presentationMode
                )
            case let .cameraResult(scannedCode):
                OTPCodeDetailView(
                    newCodeWithContext: scannedCode,
                    navigationPath: $navigationPath,
                    dataModel: dataModel,
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
            SingleCodeScannerView(scanner: scanner, isImagePickerVisible: $isCodeImagePickerGalleryVisible)
                .padding()
                .modifier(HorizontallyCenter())
        }
    }
}
