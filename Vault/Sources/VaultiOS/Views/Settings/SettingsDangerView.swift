import Foundation
import SwiftUI
import VaultFeed

struct SettingsDangerView: View {
    private var viewModel: SettingsDangerViewModel
    @State private var deleteError: PresentationError?

    init(viewModel: SettingsDangerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            headerSection
            actionSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.isDeleting)
    }

    private var headerSection: some View {
        Section {
            PlaceholderView(
                systemIcon: "exclamationmark.triangle.fill",
                title: "Danger Zone",
                subtitle: "Be careful what you do here."
            )
            .padding()
            .containerRelativeFrame(.horizontal)
            .foregroundStyle(.red)
        }
    }

    private var actionSection: some View {
        Section {
            AsyncButton {
                do {
                    withAnimation {
                        deleteError = nil
                    }
                    try await viewModel.deleteEntireVault()
                } catch let error as PresentationError {
                    withAnimation {
                        deleteError = error
                    }
                }
            } label: {
                let desc = deleteError?.userDescription
                FormRow(
                    image: Image(systemName: "trash.fill"),
                    color: .red,
                    style: .standard,
                    alignment: desc == nil ? .center : .firstTextBaseline
                ) {
                    TextAndSubtitle(title: "Delete All Data", subtitle: desc)
                }
            } loading: {
                ProgressView()
                    .tint(.red)
            }
            .tint(.red)
        }
    }
}
