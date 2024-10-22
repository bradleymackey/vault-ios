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
            createSection
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
                .listRowInsets(EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16))
        }
    }

    private var createSection: some View {
        Section {
            AsyncButton {
                await viewModel.createPDF()
            } label: {
                FormRow(image: Image(systemName: "checkmark.circle.fill"), color: .accentColor, style: .standard) {
                    Text("Make PDF")
                }
            }
        } footer: {
            if case let .error(presentationError) = viewModel.state {
                Label(
                    presentationError.userDescription ?? presentationError.userTitle,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)
            }
        }
    }
}
