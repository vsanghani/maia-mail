import Foundation
import SwiftUI

@MainActor
class AccountViewModel: ObservableObject {

    @Published var currentAccount: EmailAccount?
    @Published var isTestingConnection: Bool = false
    @Published var connectionTestResult: ConnectionResult?
    @Published var errorMessage: String?

    enum ConnectionResult {
        case success
        case failure(String)
    }

    var isAccountConfigured: Bool {
        currentAccount != nil
    }

    init() {
        loadSavedAccount()
    }

    // MARK: - Account Management

    func saveAccount(_ account: EmailAccount) {
        currentAccount = account
        _ = KeychainHelper.saveAccount(account)
    }

    func signOut() {
        currentAccount = nil
        _ = KeychainHelper.deleteAccount()
    }

    private func loadSavedAccount() {
        currentAccount = KeychainHelper.loadAccount()
    }

    // MARK: - Connection Test

    func testConnection(account: EmailAccount) async {
        isTestingConnection = true
        connectionTestResult = nil
        errorMessage = nil

        let service = EmailService()
        service.configure(with: account)

        do {
            try await service.testConnection()
            connectionTestResult = .success
        } catch {
            connectionTestResult = .failure(error.localizedDescription)
            errorMessage = error.localizedDescription
        }

        isTestingConnection = false
    }
}
