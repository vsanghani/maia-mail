import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.surfaceBackground
                    .ignoresSafeArea()

                List {
                    // Account Section
                    if let account = accountViewModel.currentAccount {
                        Section {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                AvatarView(
                                    initials: String(account.displayName.prefix(2)).uppercased(),
                                    size: 56,
                                    fontSize: 20
                                )

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text(account.displayName.isEmpty ? "Account" : account.displayName)
                                        .font(AppTheme.Typography.headline)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)

                                    Text(account.email)
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)

                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        Image(systemName: account.provider.icon)
                                            .font(.system(size: 11))
                                        Text(account.provider.rawValue)
                                            .font(AppTheme.Typography.caption)
                                    }
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.sm)
                        } header: {
                            Text("Account")
                                .font(AppTheme.Typography.caption)
                        }

                        // Server Details
                        Section {
                            serverDetailRow(label: "IMAP Server", value: account.imapHost)
                            serverDetailRow(label: "IMAP Port", value: "\(account.imapPort)")
                            serverDetailRow(label: "SMTP Server", value: account.smtpHost)
                            serverDetailRow(label: "SMTP Port", value: "\(account.smtpPort)")
                            serverDetailRow(label: "Security", value: account.useSSL ? "SSL/TLS" : "None")
                        } header: {
                            Text("Server Configuration")
                                .font(AppTheme.Typography.caption)
                        }
                    }

                    // App Info
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }

                        HStack {
                            Label("Build", systemImage: "hammer")
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            Text("Swift · SwiftUI")
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    } header: {
                        Text("About Maia Mail")
                            .font(AppTheme.Typography.caption)
                    }

                    // Sign Out
                    Section {
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(AppTheme.Typography.headline)
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    accountViewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to sign in again to access your email.")
            }
        }
    }

    private func serverDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}
