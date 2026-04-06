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
    private var simulatedMessages: [EmailMessage] = []
    private var lastRemoteEmails: [EmailMessage] = []

    func configure(with accountVM: AccountViewModel) {
        self.accountViewModel = accountVM
        if let account = accountVM.currentAccount {
            emailService.configure(with: account)
            simulatedMessages = SimulatedInboxStore.load(accountEmail: account.email)
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
            lastRemoteEmails = fetched
            mergeIntoEmails()
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
        lastRemoteEmails = []
        await fetchEmails()
    }

    // MARK: - Simulated (device-local)

    func addSimulatedMessage(_ message: EmailMessage) {
        guard let email = accountViewModel?.currentAccount?.email else { return }
        simulatedMessages.insert(message, at: 0)
        SimulatedInboxStore.save(simulatedMessages, accountEmail: email)
        mergeIntoEmails()
    }

    private func persistSimulatedIfNeeded(for message: EmailMessage) {
        guard message.isSimulated, let email = accountViewModel?.currentAccount?.email else { return }
        SimulatedInboxStore.save(simulatedMessages, accountEmail: email)
    }

    private func simulatedForCurrentFolder() -> [EmailMessage] {
        guard currentFolder.uppercased() == "INBOX" else { return [] }
        return simulatedMessages.filter { $0.folder.uppercased() == "INBOX" }
    }

    private func mergeIntoEmails() {
        let merged = (simulatedForCurrentFolder() + lastRemoteEmails).sorted { $0.date > $1.date }
        withAnimation(.easeInOut(duration: 0.3)) {
            self.emails = merged
            filterEmails()
        }
    }

    private func updateSimulatedInStore(matching id: String, transform: (inout EmailMessage) -> Void) {
        guard let idx = simulatedMessages.firstIndex(where: { $0.id == id }) else { return }
        transform(&simulatedMessages[idx])
        persistSimulatedIfNeeded(for: simulatedMessages[idx])
    }

    // MARK: - Actions

    func markAsRead(_ message: EmailMessage) async {
        guard let index = emails.firstIndex(where: { $0.id == message.id }) else { return }
        emails[index].isRead = true
        if message.isSimulated {
            updateSimulatedInStore(matching: message.id) { $0.isRead = true }
        }
        filterEmails()

        if message.isSimulated { return }

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
        if message.isSimulated {
            updateSimulatedInStore(matching: message.id) { $0.isRead = false }
        }
        filterEmails()

        if message.isSimulated { return }

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
        if message.isSimulated {
            let starred = emails[index].isStarred
            updateSimulatedInStore(matching: message.id) { $0.isStarred = starred }
        }
        filterEmails()

        if message.isSimulated { return }

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
            if message.isSimulated {
                simulatedMessages.removeAll { $0.id == message.id }
                if let email = accountViewModel?.currentAccount?.email {
                    SimulatedInboxStore.save(simulatedMessages, accountEmail: email)
                }
            }
            filterEmails()
        }

        if message.isSimulated { return }

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
                email.snippet.lowercased().contains(query) ||
                email.to.contains { $0.displayName.lowercased().contains(query) || $0.address.lowercased().contains(query) } ||
                email.cc.contains { $0.displayName.lowercased().contains(query) || $0.address.lowercased().contains(query) } ||
                email.bcc.contains { $0.displayName.lowercased().contains(query) || $0.address.lowercased().contains(query) }
            }
        }
    }

    var unreadCount: Int {
        emails.filter { !$0.isRead }.count
    }

    func signOut() {
        emails = []
        filteredEmails = []
        errorMessage = nil
        simulatedMessages = []
        lastRemoteEmails = []
        accountViewModel = nil
        Task { await emailService.disconnect() }
    }
}
