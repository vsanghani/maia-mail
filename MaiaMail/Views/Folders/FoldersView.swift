import SwiftUI

struct FoldersView: View {
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @State private var selectedFolder: EmailFolder?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.surfaceBackground
                    .ignoresSafeArea()

                List {
                    Section {
                        ForEach(inboxViewModel.folders) { folder in
                            NavigationLink(value: folder) {
                                folderRow(folder)
                            }
                        }
                    } header: {
                        Text("Mailboxes")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: EmailFolder.self) { folder in
                FolderEmailListView(folder: folder)
                    .environmentObject(inboxViewModel)
            }
        }
    }

    private func folderRow(_ folder: EmailFolder) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: folder.icon)
                .font(.system(size: 18))
                .foregroundStyle(folderIconColor(folder.type))
                .frame(width: 28)

            Text(folder.name)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            if folder.unreadCount > 0 {
                Text("\(folder.unreadCount)")
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.Colors.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private func folderIconColor(_ type: EmailFolder.FolderType) -> Color {
        switch type {
        case .inbox: return AppTheme.Colors.primary
        case .sent: return AppTheme.Colors.success
        case .drafts: return AppTheme.Colors.warning
        case .trash: return AppTheme.Colors.danger
        case .spam: return AppTheme.Colors.danger.opacity(0.7)
        case .starred: return AppTheme.Colors.starYellow
        case .archive: return AppTheme.Colors.accent
        case .custom: return AppTheme.Colors.textSecondary
        }
    }
}

struct FolderEmailListView: View {
    let folder: EmailFolder
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @State private var emails: [EmailMessage] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading \(folder.name)...")
            } else if emails.isEmpty {
                EmptyStateView(
                    icon: folder.icon,
                    title: "\(folder.name) is Empty",
                    subtitle: "No emails in this folder."
                )
            } else {
                List(emails) { email in
                    NavigationLink(value: email) {
                        EmailRowView(email: email)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
                .navigationDestination(for: EmailMessage.self) { email in
                    EmailDetailView(email: email)
                        .environmentObject(inboxViewModel)
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadEmails()
        }
    }

    private func loadEmails() async {
        isLoading = true
        await inboxViewModel.switchFolder(folder.path)
        emails = inboxViewModel.emails
        isLoading = false
    }
}
