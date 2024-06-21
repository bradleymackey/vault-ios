import Foundation
import SwiftUI

struct FooterInfoLabel: View {
    var title: String
    var detail: String
    var systemImageName: String

    var body: some View {
        LabeledContent {
            Text(detail)
                .multilineTextAlignment(.trailing)
        } label: {
            Label {
                Text(title)
                    .multilineTextAlignment(.leading)
            } icon: {
                Image(systemName: systemImageName)
                    .frame(minWidth: 24)
            }
        }
        .font(.footnote)
    }
}
