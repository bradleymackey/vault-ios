import Foundation
import SwiftUI
import VaultFeed
import VaultiOS
import VaultSettings

@MainActor
struct VaultAutofillCodeSelectorView<Generator: VaultItemPreviewViewGenerator<VaultItem.Payload>>: View {
    var localSettings: LocalSettings
    var viewGenerator: Generator

    init(localSettings: LocalSettings, viewGenerator: Generator) {
        self.localSettings = localSettings
        self.viewGenerator = viewGenerator
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
                    // TODO: dismiss
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
        VaultItemOnTapDecoratorViewGenerator(generator: viewGenerator) { _ in
            // TODO: handle tap of id, return data
        }
    }
}
