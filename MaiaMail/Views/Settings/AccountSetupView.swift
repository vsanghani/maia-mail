import SwiftUI

struct AccountSetupView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @State private var account = EmailAccount.withProvider(.gmail)
    @State private var showAdvanced = false
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        AppTheme.Colors.primary.opacity(0.08),
                        AppTheme.Colors.accent.opacity(0.05),
                        AppTheme.Colors.surfaceBackground,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        // Welcome Header
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(AppTheme.Colors.accentGradient)
                                .symbolEffect(.bounce, value: animateIn)

                            Text("Welcome to Maia Mail")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            Text("Connect your email account to get started")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        .padding(.top, AppTheme.Spacing.xxxl)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Provider Selection
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("Email Provider")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.md) {
                                    ForEach(EmailAccount.EmailProvider.allCases) { provider in
                                        providerButton(provider)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Account Fields
                        VStack(spacing: AppTheme.Spacing.lg) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("Display Name")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)

                                TextField("Your Name", text: $account.displayName)
                                    .textFieldStyle(.plain)
                                    .font(AppTheme.Typography.body)
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                            }

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("Email Address")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)

                                TextField("you@example.com", text: $account.email)
                                    .textFieldStyle(.plain)
                                    .font(AppTheme.Typography.body)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                            }

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("Password / App Password")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)

                                SecureField("Password", text: $account.password)
                                    .textFieldStyle(.plain)
                                    .font(AppTheme.Typography.body)
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                            }

                            if account.provider == .gmail {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(AppTheme.Colors.primary)
                                    Text("For Gmail, use an App Password from your Google Account settings.")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                            }

                            // Advanced settings toggle
                            DisclosureGroup(isExpanded: $showAdvanced) {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    HStack {
                                        Text("IMAP Host")
                                            .font(AppTheme.Typography.caption)
                                            .frame(width: 80, alignment: .leading)
                                        TextField("imap.example.com", text: $account.imapHost)
                                            .textFieldStyle(.plain)
                                            .font(AppTheme.Typography.body)
                                            .textInputAutocapitalization(.never)
                                            .padding(AppTheme.Spacing.sm)
                                            .background(AppTheme.Colors.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                                    }

                                    HStack {
                                        Text("IMAP Port")
                                            .font(AppTheme.Typography.caption)
                                            .frame(width: 80, alignment: .leading)
                                        TextField("993", value: $account.imapPort, format: .number)
                                            .textFieldStyle(.plain)
                                            .font(AppTheme.Typography.body)
                                            .keyboardType(.numberPad)
                                            .padding(AppTheme.Spacing.sm)
                                            .background(AppTheme.Colors.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                                    }

                                    HStack {
                                        Text("SMTP Host")
                                            .font(AppTheme.Typography.caption)
                                            .frame(width: 80, alignment: .leading)
                                        TextField("smtp.example.com", text: $account.smtpHost)
                                            .textFieldStyle(.plain)
                                            .font(AppTheme.Typography.body)
                                            .textInputAutocapitalization(.never)
                                            .padding(AppTheme.Spacing.sm)
                                            .background(AppTheme.Colors.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                                    }

                                    HStack {
                                        Text("SMTP Port")
                                            .font(AppTheme.Typography.caption)
                                            .frame(width: 80, alignment: .leading)
                                        TextField("465", value: $account.smtpPort, format: .number)
                                            .textFieldStyle(.plain)
                                            .font(AppTheme.Typography.body)
                                            .keyboardType(.numberPad)
                                            .padding(AppTheme.Spacing.sm)
                                            .background(AppTheme.Colors.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                                    }

                                    Toggle("Use SSL/TLS", isOn: $account.useSSL)
                                        .font(AppTheme.Typography.subheadline)
                                }
                                .padding(.top, AppTheme.Spacing.md)
                            } label: {
                                Text("Advanced Settings")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(AppTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        // Buttons
                        VStack(spacing: AppTheme.Spacing.md) {
                            // Test Connection
                            Button {
                                Task {
                                    await accountViewModel.testConnection(account: account)
                                }
                            } label: {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    if accountViewModel.isTestingConnection {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text(accountViewModel.isTestingConnection ? "Testing..." : "Test Connection")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                        .strokeBorder(AppTheme.Colors.primary.opacity(0.5), lineWidth: 1.5)
                                )
                            }
                            .disabled(account.email.isEmpty || account.password.isEmpty || accountViewModel.isTestingConnection)
                            .foregroundStyle(AppTheme.Colors.primary)

                            // Connection test result
                            if let result = accountViewModel.connectionTestResult {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    switch result {
                                    case .success:
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.success)
                                        Text("Connection successful!")
                                            .foregroundStyle(AppTheme.Colors.success)
                                    case .failure(let msg):
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.danger)
                                        Text(msg)
                                            .foregroundStyle(AppTheme.Colors.danger)
                                    }
                                }
                                .font(AppTheme.Typography.caption)
                                .padding(AppTheme.Spacing.sm)
                            }

                            // Sign In
                            Button {
                                accountViewModel.saveAccount(account)
                                inboxViewModel.configure(with: accountViewModel)
                            } label: {
                                Text("Sign In")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.Spacing.md + 2)
                                    .background(AppTheme.Colors.accentGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                                    .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(account.email.isEmpty || account.password.isEmpty)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    animateIn = true
                }
            }
            .onChange(of: account.provider) { _, newProvider in
                let config = newProvider.defaultConfig
                account.imapHost = config.imapHost
                account.imapPort = config.imapPort
                account.smtpHost = config.smtpHost
                account.smtpPort = config.smtpPort
            }
        }
    }

    private func providerButton(_ provider: EmailAccount.EmailProvider) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                account.provider = provider
            }
        } label: {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: provider.icon)
                    .font(.system(size: 24))
                    .frame(width: 52, height: 52)
                    .background(
                        account.provider == provider
                            ? AppTheme.Colors.primary.opacity(0.15)
                            : AppTheme.Colors.cardBackground
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .strokeBorder(
                                account.provider == provider
                                    ? AppTheme.Colors.primary
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )

                Text(provider.rawValue)
                    .font(AppTheme.Typography.caption2)
            }
            .foregroundStyle(
                account.provider == provider
                    ? AppTheme.Colors.primary
                    : AppTheme.Colors.textSecondary
            )
        }
    }
}
