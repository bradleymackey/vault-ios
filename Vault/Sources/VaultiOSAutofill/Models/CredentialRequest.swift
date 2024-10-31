import Foundation

enum CredentialRequest: Equatable {
    case domain(String)
    case url(String)
    case substring(String)
}
