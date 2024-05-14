import Foundation
import FoundationExtensions

/// The size that an OTP preview window will be when presented.
public enum PreviewSize: String, Codable, Equatable, Hashable, CaseIterable, IdentifiableSelf {
    case medium
    case large
}

extension PreviewSize {
    /// The default suggested size to use as a preview size.
    public static let `default`: PreviewSize = .medium
}

extension PreviewSize {
    public var localizedName: String {
        switch self {
        case .medium:
            localized(key: "previewSize.medium")
        case .large:
            localized(key: "previewSize.large")
        }
    }
}
