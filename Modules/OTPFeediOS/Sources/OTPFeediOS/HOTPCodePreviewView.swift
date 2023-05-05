import OTPFeed
import SwiftUI

struct HOTPCodePreviewView: View {
    var accountName: String
    var issuer: String?
    var textView: CodeTextView
    var buttonView: CodeButtonView
    @ObservedObject var previewViewModel: CodePreviewViewModel

    var body: some View {
        HStack(alignment: .center) {
            OTPCodeLabels(accountName: accountName, issuer: issuer)
            Spacer()
            buttonView
        }
    }
}
