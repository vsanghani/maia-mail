import Foundation
import SwiftUI

@MainActor
class ComposeViewModel: ObservableObject {

    @Published var toField: String = ""
    @Published var ccField: String = ""
    @Published var bccField: String = ""
    @Published var subjectField: String = ""
    @Published var bodyField: String = ""
    @Published var showCCBCC: Bool = false
    @Published var isSending: Bool = false
    @Published var sendSuccess: Bool = false
    @Published var errorMessage: String?

    private let emailService = EmailService()
    private var account: EmailAccount?

    var canSend: Bool {
        !toField.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subjectField.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasContent: Bool {
        !toField.isEmpty || !subjectField.isEmpty || !bodyField.isEmpty
    }

    func configure(with account: EmailAccount) {
        self.account = account
        emailService.configure(with: account)
    }

    // MARK: - Reply / Forward

    func setupReply(to message: EmailMessage) {
        toField = message.from.address
        subjectField = message.subject.hasPrefix("Re:") ? message.subject : "Re: \(message.subject)"
        bodyField = "\n\n--- Original Message ---\nFrom: \(message.from.formatted)\nDate: \(message.formattedDate)\n\n\(message.body)"
    }

    func setupForward(_ message: EmailMessage) {
        subjectField = message.subject.hasPrefix("Fwd:") ? message.subject : "Fwd: \(message.subject)"
        bodyField = "\n\n--- Forwarded Message ---\nFrom: \(message.from.formatted)\nTo: \(message.to.map { $0.formatted }.joined(separator: ", "))\nDate: \(message.formattedDate)\nSubject: \(message.subject)\n\n\(message.body)"
    }

    // MARK: - Send

    func send() async {
        guard canSend else { return }

        isSending = true
        errorMessage = nil

        let recipients = toField
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let ccRecipients = ccField
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let bccRecipients = bccField
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        do {
            try await emailService.sendEmail(
                to: recipients,
                cc: ccRecipients,
                bcc: bccRecipients,
                subject: subjectField,
                body: bodyField
            )
            sendSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    // MARK: - Reset

    func reset() {
        toField = ""
        ccField = ""
        bccField = ""
        subjectField = ""
        bodyField = ""
        showCCBCC = false
        isSending = false
        sendSuccess = false
        errorMessage = nil
    }
}
