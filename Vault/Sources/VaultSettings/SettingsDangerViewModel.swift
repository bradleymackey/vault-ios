import Foundation
import VaultFeed

@MainActor
@Observable
public final class SettingsDangerViewModel {
    public private(set) var isDeleting = false
    private let dataModel: VaultDataModel
    private let authenticationService: DeviceAuthenticationService

    public init(dataModel: VaultDataModel, authenticationService: DeviceAuthenticationService) {
        self.dataModel = dataModel
        self.authenticationService = authenticationService
    }

    public func deleteEntireVault() async throws(PresentationError) {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await authenticationService.validateAuthentication(reason: "Delete Vault")
            try await dataModel.deleteVault()
            try await Task.sleep(for: .seconds(2)) // might be really fast, make it noticable
        } catch {
            throw .init(
                userTitle: "Can't delete Vault",
                userDescription: "Unable to delete Vault data right now. Please try again. \(error.localizedDescription)",
                debugDescription: error.localizedDescription
            )
        }
    }
}
