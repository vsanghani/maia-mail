import Foundation
import SwiftUI

@MainActor
class InboxViewModel: ObservableObject {

    @Published var emails: [EmailMessage] = []
    @Published var filteredEmails: [EmailMessage] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = "" {
        didSet { filterEmails() }
    }
    @Published var currentFolder: String = "INBOX"
    @Published var folders: [EmailFolder] = EmailFolder.defaultFolders

    private let emailService = EmailService()
    private var accountViewModel: AccountViewModel?

    func configure(with accountVM: AccountViewModel) {
        self.accountViewModel = accountVM
        if let account = accountVM.currentAccount {
            emailService.configure(with: account)
            Task { await fetchEmails() }
        }
    }

    // MARK: - Fetch

    func fetchEmails() async {
        guard emailService.isConfigured else { return }

        isLoading = emails.isEmpty
        isRefreshing = !emails.isEmpty
        errorMessage = nil

        do {
            let fetched = try await emailService.fetchEmails(folder: currentFolder)
            withAnimation(.easeInOut(duration: 0.3)) {
                self.emails = fetched
                filterEmails()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        isRefreshing = false
    }

    func refresh() async {
        await fetchEmails()
    }

    func switchFolder(_ folder: String) async {
        currentFolder = folder
        emails = []
        await fetchEmails()
    }

    // MARK: - Actions

    func markAsRead(_ message: EmailMessage) async {
        guard let index = emails.firstIndex(where: { $0.id == message.id }) else { return }
        emails[index].isRead = true
        filterEmails()

        do {
            try await emailService.markAsRead(message: message)
        } catch {
            emails[index].isRead = false
            filterEmails()
        }
    }

    func markAsUnread(_ message: EmailMessage) async {
        guard let index = emails.firstIndex(where: { $0.id == message.id }) else { return }
        emails[index].isRead = false
        filterEmails()

        do {
            try await emailService.markAsUnread(message: message)
        } catch {
            emails[index].isRead = true
            filterEmails()
        }
    }

    func toggleStar(_ message: EmailMessage) async {
        guard let index = emails.firstIndex(where: { $0.id == message.id }) else { return }
        emails[index].isStarred.toggle()
        filterEmails()

        do {
            try await emailService.toggleStar(message: emails[index])
        } catch {
            emails[index].isStarred.toggle()
            filterEmails()
        }
    }

    func deleteMessage(_ message: EmailMessage) async {
        let backup = emails
        withAnimation {
            emails.removeAll { $0.id == message.id }
            filterEmails()
        }

        do {
            try await emailService.deleteMessage(message)
        } catch {
            emails = backup
            filterEmails()
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search / Filter

    private func filterEmails() {
        if searchText.isEmpty {
            filteredEmails = emails
        } else {
            let query = searchText.lowercased()
            filteredEmails = emails.filter { email in
                email.subject.lowercased().contains(query) ||
                email.from.displayName.lowercased().contains(query) ||
                email.from.address.lowercased().contains(query) ||
                email.snippet.lowercased().contains(query)
            }
        }
    }

    var unreadCount: Int {
        emails.filter { !$0.isRead }.count
    }
}
