import Foundation

/// Modifer to the visual behaviour of an OTP view.
///
/// This takes precedant over any content the view is currently displaying.
public enum VaultItemViewBehaviour: Equatable {
    /// Standard behaviour, the code should show the content it wants.
    case normal
    /// The item is in an "edit" state.
    /// Content may be modified to make it clear that an editing action is in progress.
    case editingState(message: String?)
}
