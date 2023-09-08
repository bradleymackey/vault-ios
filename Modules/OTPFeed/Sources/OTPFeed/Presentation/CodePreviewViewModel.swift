import Combine
import Foundation
import OTPCore

/// A preview of an OTP code.
@MainActor
public final class CodePreviewViewModel: ObservableObject {
    public let accountName: String
    public let issuer: String?
    @Published public private(set) var code: OTPCodeState = .notReady

    private var cancellables = Set<AnyCancellable>()

    public init(
        accountName: String,
        issuer: String?,
        fixedCodeState: OTPCodeState
    ) {
        self.accountName = accountName
        self.issuer = issuer
        code = fixedCodeState
    }

    public init(
        accountName: String,
        issuer: String?,
        renderer: some OTPCodeRenderer
    ) {
        self.accountName = accountName
        self.issuer = issuer
        renderer.renderedCodePublisher()
            .sink { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    code = .finished
                case let .failure(error):
                    code = .error(
                        PresentationError(
                            userTitle: localized(key: "codePreview.codeGenerationError.title"),
                            userDescription: localized(key: "codePreview.codeGenerationError.description"),
                            debugDescription: error.localizedDescription
                        ),
                        digits: 6
                    )
                }
            } receiveValue: { [weak self] code in
                guard let self else { return }
                self.code = .visible(code)
            }
            .store(in: &cancellables)
    }

    public func update(code: OTPCodeState) {
        self.code = code
    }

    public func hideCodeUntilNextUpdate() {
        code = .obfuscated
    }
}
