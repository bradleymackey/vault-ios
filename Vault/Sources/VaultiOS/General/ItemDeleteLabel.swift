import Foundation
import SwiftUI

struct ItemDeleteLabel: View {
    var body: some View {
        VStack {
            icon
            label
        }
        .foregroundColor(.red)
    }

    private var icon: some View {
        ZStack {
            Color.red

            Image(systemName: "trash.fill")
                .foregroundColor(.white)
                .font(.system(size: 25))
        }
        .clipShape(Circle())
        .frame(width: 70, height: 70)
    }

    private var label: some View {
        Text(localized(key: "action.delete.title"))
            .font(.caption.bold())
            .textCase(.uppercase)
    }
}

struct ItemDeleteLabel_Previews: PreviewProvider {
    static var previews: some View {
        ItemDeleteLabel()
    }
}
