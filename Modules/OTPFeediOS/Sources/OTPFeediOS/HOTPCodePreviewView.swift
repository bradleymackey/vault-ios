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
            labels
            Spacer()
            buttonView
        }
    }

    private var labels: some View {
        VStack {
            Text("HOTP!")
            Text(accountName)
            textView
        }
    }
}
