import SwiftUI

struct InboxView: View {
    @EnvironmentObject var viewModel: InboxViewModel
    @State private var selectedEmail: EmailMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.surfaceBackground
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.emails.isEmpty {
                    LoadingView(message: "Fetching emails...")
                } else if viewModel.filteredEmails.isEmpty && !viewModel.searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "No emails match \"\(viewModel.searchText)\""
                    )
                } else if viewModel.emails.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "Inbox is Empty",
                        subtitle: "No emails to display. Pull down to refresh."
                    )
                } else {
                    emailList
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search emails...")
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .tint(AppTheme.Colors.primary)
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
                Button("Retry") {
                    Task { await viewModel.fetchEmails() }
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var emailList: some View {
        List {
            ForEach(viewModel.filteredEmails) { email in
                NavigationLink(value: email) {
                    EmailRowView(email: email)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteMessage(email) }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }

                    Button {
                        Task {
                            if email.isRead {
                                await viewModel.markAsUnread(email)
                            } else {
                                await viewModel.markAsRead(email)
                            }
                        }
                    } label: {
                        Label(
                            email.isRead ? "Unread" : "Read",
                            systemImage: email.isRead ? "envelope.badge.fill" : "envelope.open.fill"
                        )
                    }
                    .tint(AppTheme.Colors.primary)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        Task { await viewModel.toggleStar(email) }
                    } label: {
                        Label(
                            email.isStarred ? "Unstar" : "Star",
                            systemImage: email.isStarred ? "star.slash.fill" : "star.fill"
                        )
                    }
                    .tint(AppTheme.Colors.starYellow)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: EmailMessage.self) { email in
            EmailDetailView(email: email)
                .environmentObject(viewModel)
        }
    }
}
