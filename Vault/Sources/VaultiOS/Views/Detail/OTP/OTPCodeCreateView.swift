import CodeScanner
import Foundation
import SwiftUI
import VaultFeed

@MainActor
struct OTPCodeCreateView<
    PreviewGenerator: VaultItemPreviewViewGenerator & VaultItemCopyActionHandler
>: View where PreviewGenerator.PreviewItem == VaultItem.Payload {
    var previewGenerator: PreviewGenerator
    @Binding var navigationPath: NavigationPath
    @State private var scanner: CodeScanningManager<OTPCodeScanningHandler>

    init(
        previewGenerator: PreviewGenerator,
        navigationPath: Binding<NavigationPath>,
        intervalTimer: any IntervalTimer
    ) {
        self.previewGenerator = previewGenerator
        _navigationPath = navigationPath
        let manager = CodeScanningManager(intervalTimer: intervalTimer, handler: OTPCodeScanningHandler())
        _scanner = .init(wrappedValue: manager)
    }

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
                    editor: VaultDataModelEditorAdapter(dataModel: dataModel),
                    previewGenerator: previewGenerator,
                    presentationMode: presentationMode
                )
            case let .cameraResult(scannedCode):
                OTPCodeDetailView(
                    newCodeWithContext: scannedCode,
                    navigationPath: $navigationPath,
                    dataModel: dataModel,
                    editor: VaultDataModelEditorAdapter(dataModel: dataModel),
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
                Label("Select image from library", systemImage: "qrcode.viewfinder")
            }
            .foregroundStyle(.primary)

            NavigationLink(value: CreationMode.manually) {
                Label("Enter details manually", systemImage: "entry.lever.keypad")
            }
            .foregroundStyle(.primary)
        } header: {
            CodeScanningView(
                scanner: scanner,
                isImagePickerVisible: $isCodeImagePickerGalleryVisible
            )
            .padding()
            .modifier(HorizontallyCenter())
        }
    }
}
