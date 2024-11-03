import Foundation

public final class FAQCodesFileContent: FileBackedContent {
    public let fileName: String = "FAQ-Codes"
    public let fileExtension: String = "md"

    public init() {}
}

public final class FAQBackupsGeneralFileContent: FileBackedContent {
    public let fileName: String = "FAQ-Backups-General"
    public let fileExtension: String = "md"

    public init() {}
}

public final class FAQBackupsSecurityFileContent: FileBackedContent {
    public let fileName: String = "FAQ-Backups-Security"
    public let fileExtension: String = "md"

    public init() {}
}

public struct PrivacyPolicyContent: FileBackedContent {
    public let fileName: String = "PrivacyPolicy"
    public let fileExtension: String = "md"

    public init() {}
}

public struct TermsOfServiceContent: FileBackedContent {
    public let fileName: String = "TermsOfService"
    public let fileExtension: String = "md"

    public init() {}
}
