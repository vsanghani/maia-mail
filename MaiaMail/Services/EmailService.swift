import Foundation

/// High-level email service orchestrating IMAP and SMTP operations.
class EmailService: ObservableObject {

    private var imapService: IMAPService?
    private var smtpService: SMTPService?
    private var account: EmailAccount?

    var isConfigured: Bool { account != nil }

    // MARK: - Configuration

    func configure(with account: EmailAccount) {
        if let existing = imapService {
            Task { await existing.disconnect() }
        }
        self.account = account
        self.imapService = IMAPService(
            host: account.imapHost,
            port: account.imapPort,
            useSSL: account.useSSL
        )
        self.smtpService = SMTPService(
            host: account.smtpHost,
            port: account.smtpPort,
            useSSL: account.useSSL
        )
    }

    func disconnect() async {
        await imapService?.disconnect()
    }

    // MARK: - Test Connection

    func testConnection() async throws {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.connect()
        try await imapService.login(email: account.email, password: account.password)
        await imapService.disconnect()
    }

    // MARK: - Fetch Emails

    func fetchEmails(folder: String = "INBOX", limit: Int = 50) async throws -> [EmailMessage] {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.ensureConnected(email: account.email, password: account.password)
        return try await imapService.fetchMessages(folder: folder, limit: limit)
    }

    // MARK: - Fetch Folders

    func fetchFolders() async throws -> [String] {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.ensureConnected(email: account.email, password: account.password)
        return try await imapService.listFolders()
    }

    // MARK: - Send Email

    func sendEmail(
        to: [String],
        cc: [String] = [],
        bcc: [String] = [],
        subject: String,
        body: String
    ) async throws {
        guard let account = account, let smtpService = smtpService else {
            throw EmailServiceError.notConfigured
        }

        try await smtpService.connect()
        try await smtpService.sendEmail(
            from: account.email,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            username: account.email,
            password: account.password
        )
        await smtpService.disconnect()
    }

    // MARK: - Flag Operations

    func markAsRead(message: EmailMessage) async throws {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.ensureConnected(email: account.email, password: account.password)
        try await imapService.markAsRead(folder: message.folder, uid: message.uid)
    }

    func markAsUnread(message: EmailMessage) async throws {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.ensureConnected(email: account.email, password: account.password)
        try await imapService.markAsUnread(folder: message.folder, uid: message.uid)
    }

    func toggleStar(message: EmailMessage) async throws {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.ensureConnected(email: account.email, password: account.password)
        try await imapService.toggleStar(folder: message.folder, uid: message.uid, star: !message.isStarred)
    }

    func deleteMessage(_ message: EmailMessage) async throws {
        guard let account = account, let imapService = imapService else {
            throw EmailServiceError.notConfigured
        }

        try await imapService.ensureConnected(email: account.email, password: account.password)
        try await imapService.deleteMessage(folder: message.folder, uid: message.uid)
    }
}

// MARK: - Errors

enum EmailServiceError: LocalizedError {
    case notConfigured
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "No email account configured"
        case .operationFailed(let msg): return "Operation failed: \(msg)"
        }
    }
}
