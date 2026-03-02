import SwiftUI

@main
struct MaiaMailApp: App {
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var inboxViewModel = InboxViewModel()

    var body: some Scene {
        WindowGroup {
            if accountViewModel.isAccountConfigured {
                MainTabView()
                    .environmentObject(accountViewModel)
                    .environmentObject(inboxViewModel)
                    .onAppear {
                        inboxViewModel.configure(with: accountViewModel)
                    }
            } else {
                AccountSetupView()
                    .environmentObject(accountViewModel)
                    .environmentObject(inboxViewModel)
            }
        }
    }
}
