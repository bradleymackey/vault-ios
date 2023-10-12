import Combine
import Foundation

public final class SettingsViewModel {
    public init() {}
}

// MARK: - Strings

public extension SettingsViewModel {
    var title: String {
        localized(key: "home.title")
    }

    var viewOptionsSectionTitle: String {
        localized(key: "home.header.viewOptions.title")
    }

    var policyAndLegacySectionTitle: String {
        localized(key: "home.header.policyAndLegal.title")
    }

    var aboutTitle: String {
        localized(key: "about.title")
    }

    var previewSizeTitle: String {
        localized(key: "previewSize.title")
    }

    var pasteTTLTitle: String {
        localized(key: "pasteTTL.title")
    }

    var saveBackupTitle: String {
        localized(key: "saveBackup.title")
    }

    var restoreBackupTitle: String {
        localized(key: "restoreBackup.title")
    }

    var openSourceTitle: String {
        localized(key: "openSource.title")
    }

    var thirdPartyTitle: String {
        localized(key: "thirdPartyLibraries.title")
    }

    var privacyPolicyTitle: String {
        localized(key: "privacyPolicy.title")
    }

    var termsOfUseTitle: String {
        localized(key: "termsOfUse.title")
    }
}
