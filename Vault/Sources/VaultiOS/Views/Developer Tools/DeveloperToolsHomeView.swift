import SwiftUI

struct DeveloperToolsHomeView: View {
    enum Destination: Hashable {
        case createItems
    }

    var body: some View {
        Form {
            NavigationLink(value: Destination.createItems) {
                Text("Create Items")
            }
        }
        .navigationTitle("Developer")
        .navigationDestination(for: Destination.self) { item in
            switch item {
            case .createItems:
                DeveloperCreateItemsView()
            }
        }
    }
}
