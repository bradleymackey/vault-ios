import Foundation
import SwiftUI

struct HeaderIcon: View {
    var image: Image
    var color: Color

    var body: some View {
        HStack {
            image
                .font(.system(size: 24))
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
                .foregroundStyle(.white)
                .frame(maxWidth: 48, maxHeight: 48)
                .background(color)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
