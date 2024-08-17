import Foundation
import SwiftUI

/// A button that supports binding to a Task action.
///
/// Attribution: https://www.swiftbysundell.com/articles/building-an-async-swiftui-button/
struct AsyncButton<Label: View>: View {
    var progressAlignment: Alignment = .center
    var action: () async -> Void
    var actionOptions = Set(ActionOption.allCases)
    @ViewBuilder var label: () -> Label

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
                            showProgressView = true
                        }
                    }

                    await action()
                    progressViewTask?.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                ZStack(alignment: progressAlignment) {
                    label().opacity(showProgressView ? 0 : 1)

                    if showProgressView {
                        ProgressView()
                    }
                }
            }
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

extension AsyncButton where Label == Text {
    init(
        _ label: String,
        actionOptions _: Set<ActionOption> = Set(ActionOption.allCases),
        action: @escaping () async -> Void
    ) {
        self.init(action: action) {
            Text(label)
        }
    }
}

extension AsyncButton where Label == Image {
    init(
        systemImageName: String,
        actionOptions _: Set<ActionOption> = Set(ActionOption.allCases),
        action: @escaping () async -> Void
    ) {
        self.init(action: action) {
            Image(systemName: systemImageName)
        }
    }
}
