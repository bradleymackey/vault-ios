import Foundation

public final class AboutCodesViewModel: FileBackedContentViewModel {
    public let fileName: String = "About-Codes"
    public let fileExtension: String = "md"

    public init() {}
}

public final class AboutBackupsViewModel: FileBackedContentViewModel {
    public let fileName: String = "About-Backups"
    public let fileExtension: String = "md"

    public init() {}
}

public final class AboutSecurityViewModel: FileBackedContentViewModel {
    public let fileName: String = "About-Security"
    public let fileExtension: String = "md"

    public init() {}
}
