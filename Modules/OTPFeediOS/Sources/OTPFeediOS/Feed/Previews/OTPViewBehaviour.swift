import Foundation

/// Modifer to the visual behaviour of an OTP view.
///
/// This takes precedant over any content the view is currently displaying.
public enum OTPViewBehaviour: Equatable {
    /// Standard behaviour, the code should show the content it wants.
    case normal
    /// Hide all code details from view, showing the optional message.
    case obfuscate(message: String?)
}
