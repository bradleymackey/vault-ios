@_exported import AlertToast

public extension AlertToast {
    static func copiedToClipboard() -> AlertToast {
        AlertToast(
            displayMode: .hud,
            type: .systemImage("doc.on.doc.fill", .primary),
            title: localized(key: "code.copyied")
        )
    }
}
