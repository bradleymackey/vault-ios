import Foundation
import SwiftUI

struct OTPCodeButtonIcon: View {
    var isError: Bool

    var body: some View {
        Image(systemName: isError ? "exclamationmark.circle.fill" : "arrow.clockwise")
    }
}
