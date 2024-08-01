import Foundation
import SwiftUI

struct LockedDetailView: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)

                Text("Item Locked")
                    .font(.title)
                    .fontWeight(.heavy)
            }

            StandaloneButton {
                action()
            } content: {
                Text("Unlock")
            }
        }
    }
}
