import Foundation

/// Modifer to the visual behaviour of an OTP view.
///
/// This takes precedant over any content the view is currently displaying.
public enum OTPViewBehaviour: Equatable {
    /// Hide all code details from view, showing the optional message.
    case obfuscate(message: String?)
}
