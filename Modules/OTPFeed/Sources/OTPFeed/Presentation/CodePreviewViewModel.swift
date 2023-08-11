import Combine
import Foundation
import OTPCore

/// A preview of an OTP code.
@MainActor
public final class CodePreviewViewModel: ObservableObject {
    public let accountName: String
    public let issuer: String?
    @Published public private(set) var code: OTPCodeState = .notReady

    private let onCodeTap: ((OTPCodeState) -> Void)?
    private var cancellables = Set<AnyCancellable>()

    public var allowsCodeTapAction: Bool {
        onCodeTap != nil
    }

    public init(
        accountName: String,
        issuer: String?,
        fixedCodeState: OTPCodeState,
        onCodeTap: ((OTPCodeState) -> Void)? = nil
    ) {
        self.accountName = accountName
        self.issuer = issuer
        self.onCodeTap = onCodeTap
        code = fixedCodeState
    }

    public init(
        accountName: String,
        issuer: String?,
        renderer: some OTPCodeRenderer,
        onCodeTap: ((OTPCodeState) -> Void)? = nil
    ) {
        self.accountName = accountName
        self.issuer = issuer
        self.onCodeTap = onCodeTap
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

    public func didTapCode() {
        onCodeTap?(code)
    }

    public func hideCodeUntilNextUpdate() {
        code = .obfuscated
    }
}
