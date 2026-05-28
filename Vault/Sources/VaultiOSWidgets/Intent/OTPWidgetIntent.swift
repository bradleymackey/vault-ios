import AppIntents
import WidgetKit

/// Configuration intent backing the OTP widget's edit sheet. The user picks
/// a single OTP item; everything else is derived from current item state at
/// timeline-build time.
public struct OTPWidgetIntent: WidgetConfigurationIntent {
    public nonisolated static let title: LocalizedStringResource = "Pick OTP Code"
    public nonisolated static let description = IntentDescription("Show a one-time code in the widget.")

    @Parameter(title: "Code")
    public var item: OTPWidgetItemEntity?

    public init() {}

    public init(item: OTPWidgetItemEntity?) {
        self.item = item
    }
}
