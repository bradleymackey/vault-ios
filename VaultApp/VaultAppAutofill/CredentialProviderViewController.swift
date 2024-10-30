import AuthenticationServices

final class CredentialProviderViewController: ASCredentialProviderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareInterfaceForExtensionConfiguration() {
        super.prepareInterfaceForExtensionConfiguration()
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
    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        print("PREPARE LIST")
    }
    
    struct CredentialTypeNotSupportedError: Error, LocalizedError {
        var errorDescription: String? {
            "Credential type is not supported by Vault"
        }
    }
    
    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        guard credentialRequest.type == .oneTimeCode else {
            extensionContext.cancelRequest(withError: CredentialTypeNotSupportedError())
            return
        }
        let credential = ASOneTimeCodeCredential(code: "123456")
        extensionContext.completeOneTimeCodeRequest(using: credential)
    }

    /*
     Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        let databaseIsUnlocked = true
        if (databaseIsUnlocked) {
            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } else {
            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code:ASExtensionError.userInteractionRequired.rawValue))
        }
    }
    */

    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
    }
    */

    @IBAction func cancel(_ sender: AnyObject?) {
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }

    @IBAction func passwordSelected(_ sender: AnyObject?) {
        let exampleCredential = ASOneTimeCodeCredential(code: "123456")
        extensionContext.completeOneTimeCodeRequest(using: exampleCredential)
    }
}

// MARK: - Unused at the moment

extension CredentialProviderViewController {
    // For passwords and passkeys
//    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
//    }
}
