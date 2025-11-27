import Foundation
import PDFKit
import SwiftUI
import VaultFeed

@MainActor
struct BackupCreatePDFView: View {
    typealias ViewModel = BackupCreatePDFViewModel
    @State private var viewModel: ViewModel
    @Binding private var navigationPath: NavigationPath

    init(viewModel: BackupCreatePDFViewModel, navigationPath: Binding<NavigationPath>) {
        _viewModel = .init(initialValue: viewModel)
        _navigationPath = navigationPath
    }

    var body: some View {
        Form {
            optionsSection
        }
        .navigationTitle(Text("Create PDF"))
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.generatedPDFPublisher(), perform: { value in
            navigationPath.append(value)
        })
    }

    private var optionsSection: some View {
        Section {
            Picker(selection: $viewModel.size) {
                ForEach(ViewModel.Size.allCases) { format in
                    Text(format.localizedTitle)
                        .tag(format)
                }
            } label: {
                FormRow(image: Image(systemName: "newspaper.fill"), color: .accentColor, style: .standard) {
                    Text("Paper Size")
                }
            }

            TextEditor(text: $viewModel.userHint)
                .font(.callout)
                .frame(minHeight: 150)
                .keyboardType(.default)
                .listRowInsets(EdgeInsets())
        } footer: {
            VStack(alignment: .center, spacing: 8) {
                createPDFButton
                if case let .error(presentationError) = viewModel.state {
                    Label(
                        presentationError.userDescription ?? presentationError.userTitle,
                        systemImage: "exclamationmark.triangle.fill",
                    )
                    .foregroundStyle(.red)
                    .font(.caption)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
    }

    private var createPDFButton: some View {
        AsyncButton {
            await viewModel.createPDF()
        } label: {
            Label("Make PDF", systemImage: "checkmark.circle.fill")
        } loading: {
            ProgressView()
                .tint(.white)
        }
        .modifier(ProminentButtonModifier())
    }
}
