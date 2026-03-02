import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @State private var selectedTab: Tab = .inbox
    @State private var showCompose = false

    enum Tab: String {
        case inbox = "Inbox"
        case folders = "Folders"
        case settings = "Settings"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                InboxView()
                    .environmentObject(inboxViewModel)
                    .tabItem {
                        Label("Inbox", systemImage: "tray.fill")
                    }
                    .tag(Tab.inbox)
                    .badge(inboxViewModel.unreadCount)

                FoldersView()
                    .environmentObject(inboxViewModel)
                    .tabItem {
                        Label("Folders", systemImage: "folder.fill")
                    }
                    .tag(Tab.folders)

                SettingsView()
                    .environmentObject(accountViewModel)
                    .environmentObject(inboxViewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(Tab.settings)
            }
            .tint(AppTheme.Colors.primary)

            // Floating Compose Button
            if selectedTab != .settings {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.Colors.accentGradient)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeView()
                .environmentObject(accountViewModel)
                .environmentObject(inboxViewModel)
        }
    }
}
