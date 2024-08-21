import SimpleToast
import SwiftUI

struct ToastAlertMessageView: View {
    var title: String
    var image: Image

    var body: some View {
        Label {
            Text(title)
        } icon: {
            image
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue)
        .foregroundColor(Color.white)
        .clipShape(Capsule())
        .font(.callout)
    }
}

extension ToastAlertMessageView {
    static func copiedToClipboard() -> ToastAlertMessageView {
        .init(title: localized(key: "code.copyied"), image: Image(systemName: "doc.on.doc.fill"))
    }
}
