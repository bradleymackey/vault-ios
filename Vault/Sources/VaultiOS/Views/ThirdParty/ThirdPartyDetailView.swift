import Foundation
import SwiftUI
import VaultSettings

struct ThirdPartyDetailView: View {
    let library: ThirdPartyLibrary

    var body: some View {
        LiteratureView(title: library.name, bodyText: .markdown(.init(library.licence)), bodyColor: .secondary)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Link(destination: library.url) {
                        Image(systemName: "link")
                    }
                }
            }
    }
}
