import SwiftUI

struct EmailRowView: View {
    let email: EmailMessage

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            // Avatar
            AvatarView(
                initials: email.senderInitials,
                size: 44,
                fontSize: 15
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // Top row: sender + date
                HStack {
                    Text(email.from.displayName)
                        .font(email.isRead ? AppTheme.Typography.subheadline : AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(email.formattedDate)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }

                // Subject
                Text(email.subject)
                    .font(email.isRead ? AppTheme.Typography.subheadline : .system(.subheadline, design: .default).weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                // Snippet
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    if email.isStarred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.Colors.starYellow)
                            .offset(y: 2)
                    }

                    Text(email.snippet)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }

            // Unread dot
            if !email.isRead {
                Circle()
                    .fill(AppTheme.Colors.primary)
                    .frame(width: 8, height: 8)
                    .offset(y: 6)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .contentShape(Rectangle())
    }
}
