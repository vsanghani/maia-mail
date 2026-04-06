import SwiftUI

/// Creates a device-local inbox message with arbitrary headers for demos or training — nothing is sent over SMTP.
struct ForgeEmailView: View {
    @EnvironmentObject var inboxViewModel: InboxViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fromName: String = ""
    @State private var fromAddress: String = ""
    @State private var toLines: String = ""
    @State private var ccLines: String = ""
    @State private var bccLines: String = ""
    @State private var subject: String = ""
    @State private var body: String = ""
    @State private var messageDate: Date = Date()
    @State private var markUnread: Bool = false

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This adds a message only on this device. No email is transmitted.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Section("From") {
                    TextField("Display name (optional)", text: $fromName)
                    TextField("Email address", text: $fromAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Recipients") {
                    TextField("To (one per line)", text: $toLines, axis: .vertical)
                        .lineLimit(3...8)
                    TextField("Cc (optional)", text: $ccLines, axis: .vertical)
                        .lineLimit(2...6)
                    TextField("Bcc (optional)", text: $bccLines, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("Content") {
                    TextField("Subject", text: $subject)
                    TextField("Body", text: $body, axis: .vertical)
                        .lineLimit(6...24)
                }

                Section("Appearance") {
                    DatePicker("Date shown", selection: $messageDate)
                    Toggle("Show as unread", isOn: $markUnread)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Simulated message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Inbox") { addMessage() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func addMessage() {
        errorMessage = nil

        let fromAddr = fromAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fromAddr.isEmpty else {
            errorMessage = "From address is required."
            return
        }

        let to = EmailAddress.parseRecipientList(toLines)
        guard !to.isEmpty else {
            errorMessage = "Add at least one To recipient (one address per line)."
            return
        }

        let from = EmailAddress(
            name: {
                let n = fromName.trimmingCharacters(in: .whitespacesAndNewlines)
                return n.isEmpty ? nil : n
            }(),
            address: fromAddr
        )

        let cc = EmailAddress.parseRecipientList(ccLines)
        let bcc = EmailAddress.parseRecipientList(bccLines)

        let snippet = String(body.prefix(150))
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let msg = EmailMessage(
            id: "local-\(UUID().uuidString)",
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
            body: body,
            htmlBody: nil,
            date: messageDate,
            isRead: !markUnread,
            isStarred: false,
            folder: "INBOX",
            snippet: snippet.isEmpty ? " " : snippet,
            uid: 0,
            isSimulated: true
        )

        inboxViewModel.addSimulatedMessage(msg)
        dismiss()
    }
}
