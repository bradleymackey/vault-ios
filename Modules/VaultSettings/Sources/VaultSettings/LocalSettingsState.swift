import Foundation

/// Local settings for the codes.
public struct LocalSettingsState: Codable {
    public var previewSize: PreviewSize
    public var pasteTimeToLive: PasteTTL
}

extension LocalSettingsState {
    static var `default`: LocalSettingsState {
        LocalSettingsState(previewSize: .default, pasteTimeToLive: .default)
    }
}
