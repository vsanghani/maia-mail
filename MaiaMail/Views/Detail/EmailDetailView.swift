import SwiftUI

struct EmailDetailView: View {
    let email: EmailMessage
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @State private var showComposeReply = false
    @State private var showComposeForward = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Card
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    // Subject
                    Text(email.subject)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Divider()

                    // Sender info
                    HStack(spacing: AppTheme.Spacing.md) {
                        AvatarView(
                            initials: email.senderInitials,
                            size: 48,
                            fontSize: 17
                        )

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(email.from.displayName)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            Text(email.from.address)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(email.formattedDate)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }

                    // Recipients
                    if !email.to.isEmpty {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("To:")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textTertiary)

                            Text(email.to.map { $0.displayName }.joined(separator: ", "))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }

                    if !email.cc.isEmpty {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("Cc:")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textTertiary)

                            Text(email.cc.map { $0.displayName }.joined(separator: ", "))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.cardBackground)

                Divider()

                // Body
                Text(email.body)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .background(AppTheme.Colors.surfaceBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { await inboxViewModel.toggleStar(email) }
                } label: {
                    Image(systemName: email.isStarred ? "star.fill" : "star")
                        .foregroundStyle(email.isStarred ? AppTheme.Colors.starYellow : AppTheme.Colors.textSecondary)
                }

                Menu {
                    Button {
                        showComposeReply = true
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                    }

                    Button {
                        showComposeForward = true
                    } label: {
                        Label("Forward", systemImage: "arrowshape.turn.up.right.fill")
                    }

                    Divider()

                    Button {
                        Task {
                            if email.isRead {
                                await inboxViewModel.markAsUnread(email)
                            } else {
                                await inboxViewModel.markAsRead(email)
                            }
                        }
                    } label: {
                        Label(
                            email.isRead ? "Mark as Unread" : "Mark as Read",
                            systemImage: email.isRead ? "envelope.badge.fill" : "envelope.open.fill"
                        )
                    }

                    Button(role: .destructive) {
                        Task {
                            await inboxViewModel.deleteMessage(email)
                            dismiss()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showComposeReply) {
            ComposeView(replyTo: email)
        }
        .sheet(isPresented: $showComposeForward) {
            ComposeView(forwardMessage: email)
        }
        .onAppear {
            if !email.isRead {
                Task { await inboxViewModel.markAsRead(email) }
            }
        }
    }
}
