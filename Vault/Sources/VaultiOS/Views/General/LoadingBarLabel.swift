import Foundation
import SwiftUI

struct LoadingBarLabel: View {
    var text: String
    var body: some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.tail)
            .textCase(.uppercase)
            .font(.system(size: 6, weight: .regular))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
    }
}
