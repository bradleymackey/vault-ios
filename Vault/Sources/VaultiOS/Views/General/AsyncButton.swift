import Foundation
import SwiftUI

/// A button that supports binding to a Task action.
///
/// Attribution: https://www.swiftbysundell.com/articles/building-an-async-swiftui-button/
struct AsyncButton<Label: View, Loading: View>: View {
    var progressAlignment: Alignment = .center
    var action: () async throws -> Void
    var actionOptions = Set(ActionOption.allCases)
    @ViewBuilder var label: () -> Label
    var loading: () -> Loading

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDisabled = false
    @State private var showProgressView = false

    var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }

                Task {
                    var progressViewTask: Task<Void, any Error>?

                    if actionOptions.contains(.showProgressView) {
                        progressViewTask = Task {
                            try await Task.sleep(for: .milliseconds(150))
                            try Task.checkCancellation()
                            showProgressView = true
                        }
                    }

                    try await action()
                    progressViewTask?.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                if showProgressView {
                    loading()
                } else {
                    label()
                }
            },
        )
        .disabled(isDisabled || !isEnabled)
    }
}

extension AsyncButton {
    enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}
