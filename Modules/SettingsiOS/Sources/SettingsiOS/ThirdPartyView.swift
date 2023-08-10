import Attribution
import SwiftUI

public struct ThirdPartyView: View {
    @State private var libraries = [ThirdPartyLibrary]()
    public init() {}

    public var body: some View {
        List {
            section
        }
        .navigationTitle("Libraries")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                let attribution = try Attribution.parse()
                libraries = attribution.libraries
            } catch {
                // TODO: handle
            }
        }
    }

    public var section: some View {
        Section {
            ForEach(libraries) { library in
                DisclosureGroup {
                    Link(destination: library.url) {
                        Text("View Source")
                            .font(.callout.bold())
                    }
                    Text(library.licence)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } label: {
                    ThirdPartyLibraryRowView(library: library)
                }
            }
        } footer: {
            Text("Thank you to all third-party software developers!")
        }
    }
}
