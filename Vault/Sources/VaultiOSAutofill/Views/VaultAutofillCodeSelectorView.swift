import Combine
import Foundation
import SwiftUI
import VaultFeed
import VaultiOS
import VaultSettings

@MainActor
struct VaultAutofillCodeSelectorView<Generator: VaultItemPreviewViewGenerator<VaultItem.Payload>>: View {
    var localSettings: LocalSettings
    var viewGenerator: Generator
    let copyActionHandler: any VaultItemCopyActionHandler
    let textToInsertSubject: PassthroughSubject<String, Never>
    let cancelSubject: PassthroughSubject<VaultAutofillViewModel.RequestCancelReason, Never>

    init(
        localSettings: LocalSettings,
        viewGenerator: Generator,
        copyActionHandler: any VaultItemCopyActionHandler,
        textToInsertSubject: PassthroughSubject<String, Never>,
        cancelSubject: PassthroughSubject<VaultAutofillViewModel.RequestCancelReason, Never>
    ) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
        self.copyActionHandler = copyActionHandler
        self.textToInsertSubject = textToInsertSubject
        self.cancelSubject = cancelSubject
    }

    @Environment(VaultDataModel.self) private var dataModel
    @Environment(DeviceAuthenticationService.self) var authenticationService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VaultItemFeedView(
            localSettings: localSettings,
            viewGenerator: interactableViewGenerator(),
            state: VaultItemFeedState(),
            gridSpacing: 12
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    cancelSubject.send(.userCancelled)
                } label: {
                    Text("Cancel")
                }
                .tint(.red)
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            viewGenerator.scenePhaseDidChange(to: newValue)
        }
        .onAppear {
            viewGenerator.didAppear()
            Task { await dataModel.reloadData() }
        }
    }

    func interactableViewGenerator() -> VaultItemOnTapDecoratorViewGenerator<Generator> {
        VaultItemOnTapDecoratorViewGenerator(generator: viewGenerator) { id in
            guard let copyAction = copyActionHandler.textToCopyForVaultItem(id: id) else {
                // ignore
                return
            }

            if copyAction.requiresAuthenticationToCopy {
                // ignore, authenticated codes cannot be copied due to the authentication UI presenting behind
                // the autofill UI
                return
            }

            textToInsertSubject.send(copyAction.text)
        }
    }
}
