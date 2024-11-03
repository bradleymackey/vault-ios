import Foundation

public final class AboutCodesViewModel: FileBackedContentViewModel {
    public let fileName: String = "FAQ-Codes"
    public let fileExtension: String = "md"

    public init() {}
}

public final class AboutBackupsGeneralViewModel: FileBackedContentViewModel {
    public let fileName: String = "FAQ-Backups-General"
    public let fileExtension: String = "md"

    public init() {}
}

public final class AboutBackupsSecurityViewModel: FileBackedContentViewModel {
    public let fileName: String = "FAQ-Backups-Security"
    public let fileExtension: String = "md"

    public init() {}
}

public final class AboutSecurityViewModel: FileBackedContentViewModel {
    public let fileName: String = "FAQ-Security"
    public let fileExtension: String = "md"

    public init() {}
}
