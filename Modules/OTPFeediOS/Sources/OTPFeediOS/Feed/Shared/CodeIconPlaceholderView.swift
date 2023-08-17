import Foundation
import SwiftUI

public struct CodeIconPlaceholderView: View {
    public let iconFontSize: Double

    public var body: some View {
        ZStack(alignment: .center) {
            Color.gray
            Image(systemName: "key.horizontal.fill")
                .foregroundColor(.white)
                .font(.system(size: iconFontSize))
        }
        .frame(width: size, height: size)
    }

    private var size: Double {
        iconFontSize * 2
    }
}
