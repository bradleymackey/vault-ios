@_exported import SimpleToast
import SwiftUI

public struct ToastAlertMessageView: View {
    public var title: String
    public var image: Image

    public var body: some View {
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
    public static func copiedToClipboard() -> ToastAlertMessageView {
        .init(title: localized(key: "code.copyied"), image: Image(systemName: "doc.on.doc.fill"))
    }
}
