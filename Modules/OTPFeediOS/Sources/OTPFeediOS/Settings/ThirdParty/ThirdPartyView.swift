import Attribution
import SwiftUI

public struct ThirdPartyView: View {
    @State private var libraries = [ThirdPartyLibrary]()
    @State private var loadingError = false
    public init() {}

    public var body: some View {
        List {
            if loadingError {
                errorSection
            } else {
                listSection
            }
        }
        .navigationTitle("Libraries")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                let attribution = try Attribution.parse()
                libraries = attribution.libraries
            } catch {
                loadingError = true
            }
        }
    }

    private var listSection: some View {
        Section {
            ForEach(libraries) { library in
                NavigationLink {
                    ThirdPartyDetailView(library: library)
                } label: {
                    ThirdPartyLibraryRowView(library: library)
                }
            }
        } footer: {
            Text("Thank you to all third-party software developers!")
        }
    }

    private var errorSection: some View {
        Section {
            Text("Error loading")
        }
    }
}
