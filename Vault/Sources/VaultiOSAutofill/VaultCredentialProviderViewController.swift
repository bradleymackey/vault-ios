import AuthenticationServices
import Combine
import SwiftUI
import VaultiOS

/// Implementation of the view controller that presents
open class VaultCredentialProviderViewController: ASCredentialProviderViewController {
    private let vaultAutofillViewModel: VaultAutofillViewModel
    private var cancellables = Set<AnyCancellable>()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        vaultAutofillViewModel = VaultAutofillViewModel(localSettings: VaultRoot.localSettings)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        let entrypointView = VaultAutofillView(
            viewModel: vaultAutofillViewModel,
            copyActionHandler: VaultRoot.vaultItemCopyHandler,
            generator: VaultRoot.genericVaultItemPreviewViewGenerator
        )
        .environment(VaultRoot.pasteboard)
        .environment(VaultRoot.deviceAuthenticationService)
        .environment(VaultRoot.vaultDataModel)
        .environment(VaultRoot.vaultInjector)

        let hosting = UIHostingController(rootView: entrypointView)
        addChild(hosting)
        view.addConstrained(subview: hosting.view)
        hosting.didMove(toParent: self)
        setupBindings()
    }

    private func setupBindings() {
        vaultAutofillViewModel.configurationDismissPublisher.sink { [weak self] in
            self?.extensionContext.completeExtensionConfigurationRequest()
        }.store(in: &cancellables)
        vaultAutofillViewModel.textToInsertPublisher.sink { [weak self] text in
            self?.extensionContext.completeRequest(withTextToInsert: text)
        }.store(in: &cancellables)
        vaultAutofillViewModel.cancelRequestPublisher.sink { [weak self] reason in
            let error = switch reason {
            case .userCancelled: ASExtensionError(.userCanceled)
            }
            self?.extensionContext.cancelRequest(withError: error)
        }.store(in: &cancellables)
    }

    // This function is called when autofill is initially enabled.
    // It allows configuration before enable.
    // It's not required, but would be good to do some config here.
    //
    // It's triggered by the "ASCredentialProviderExtensionShowsConfigurationUI" key in the Info.plist
    override open func prepareInterfaceForExtensionConfiguration() {
        vaultAutofillViewModel.show(feature: .setupConfiguration)
    }

    struct CredentialTypeNotSupportedError: Error, LocalizedError {
        var errorDescription: String? {
            "Credential type is not supported by Vault"
        }
    }

    /*
     Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.
     */
    override open func provideCredentialWithoutUserInteraction(for _: any ASCredentialRequest) {
        // TODO: OTP QuickType autofill does not currently work in iOS 18, we need to use
        // `prepareInterfaceForUserChoosingTextToInsert`
        vaultAutofillViewModel.show(feature: .unimplemented(#function))
        extensionContext.cancelRequest(withError: ASExtensionError(.userInteractionRequired))
//            let credential = ASOneTimeCodeCredential(code: "123456")
//            self.extensionContext.completeOneTimeCodeRequest(using: credential)
    }

    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated AS PasswordCredential.
     */
    override open func prepareInterfaceToProvideCredential(for _: any ASCredentialRequest) {
        vaultAutofillViewModel.show(feature: .unimplemented(#function))
    }

    /*! @abstract Prepare the view controller to show a list of one time code credentials.
     @param serviceIdentifiers the array of service identifiers.
     @discussion This method is called by the system to prepare the extension's view controller to present the list of credentials.
     A service identifier array is passed which can be used to filter or prioritize the credentials that closely match each service.
     The service identifier array could have zero or more items. If there is more than one item in the array, items with lower indexes
     represent more specific identifiers for which a credential is being requested. For example, the array could contain identifiers
     [m.example.com, example.com] with the first item representing the more specifc service that requires a credential.
     If the array of service identifiers is empty, it is expected that the credential list should still show credentials that the user can pick from.
     */
    override open func prepareOneTimeCodeCredentialList(for _: [ASCredentialServiceIdentifier]) {
        // This is not actually displayed when we want to autofill, `prepareInterfaceForUserChoosingTextToInsert`
        // is called instead.
        vaultAutofillViewModel.show(feature: .unimplemented(#function))
    }

    /*
     This method is called by the system to prepare the extension's view controller to present the list of credentials.
     A service identifier array is passed which can be used to filter or prioritize the credentials that closely match each service.
     The service identifier array could have zero or more items. If there are more than one item in the array, items with lower indexes
     represent more specific identifiers for which a credential is being requested. For example, the array could contain identifiers
     [m.example.com, example.com] with the first item representing the more specifc service that requires a credential.
     If the array of service identifiers is empty, it is expected that the credential list should still show credentials that the user can pick from.
     */
    override open func prepareCredentialList(for _: [ASCredentialServiceIdentifier]) {
        vaultAutofillViewModel.show(feature: .unimplemented(#function))
    }

    override open func prepareInterfaceForUserChoosingTextToInsert() {
        // This is the UI that appears when the user chooses to "Autofill" a "Password" with Vault.
        vaultAutofillViewModel.show(feature: .showAllCodesSelector)
    }
}

extension UIView {
    /// Add a subview, constrained to the specified top, left, bottom and right margins.
    ///
    /// - Parameters:
    ///   - view: The subview to add.
    ///
    fileprivate func addConstrained(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.preservesSuperviewLayoutMargins = false
        subview.frame = frame
        addSubview(subview)
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}
