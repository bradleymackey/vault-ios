import Foundation

/// The size that an OTP preview window will be when presented.
public enum PreviewSize: String, Codable, Equatable, Hashable, CaseIterable {
    case medium
    case large
}

extension PreviewSize {
    /// The default suggested size to use as a preview size.
    public static let `default`: PreviewSize = .medium
}

extension PreviewSize: Identifiable {
    public var id: some Hashable {
        rawValue
    }
}

extension PreviewSize {
    public var localizedName: String {
        switch self {
        case .medium:
            return localized(key: "previewSize.medium")
        case .large:
            return localized(key: "previewSize.large")
        }
    }
}
