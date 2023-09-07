import Attribution
import Foundation
import SwiftUI

struct ThirdPartyDetailView: View {
    let library: ThirdPartyLibrary

    var body: some View {
        ScrollView(.vertical) {
            Text(library.licence)
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(24)
        }
        .navigationTitle(Text(library.name))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Link(destination: library.url) {
                    Image(systemName: "link")
                }
            }
        }
    }
}
