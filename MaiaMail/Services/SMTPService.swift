import Foundation
import Network

/// SMTP client for sending emails using Apple's Network framework.
actor SMTPService {

    private var connection: NWConnection?
    private let host: String
    private let port: Int
    private let useSSL: Bool

    init(host: String, port: Int, useSSL: Bool = true) {
        self.host = host
        self.port = port
        self.useSSL = useSSL
    }

    // MARK: - Connection

    func connect() async throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 15

        let params: NWParameters
        if useSSL {
            let tlsOptions = NWProtocolTLS.Options()
            params = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        } else {
            params = NWParameters(tls: nil, tcp: tcpOptions)
        }

        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

        connection = NWConnection(host: nwHost, port: nwPort, using: params)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var resumed = false
            connection?.stateUpdateHandler = { state in
                guard !resumed else { return }
                switch state {
                case .ready:
                    resumed = true
                    continuation.resume()
                case .failed(let error):
                    resumed = true
                    continuation.resume(throwing: SMTPError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    resumed = true
                    continuation.resume(throwing: SMTPError.connectionCancelled)
                default:
                    break
                }
            }
            connection?.start(queue: .global(qos: .userInitiated))
        }
    }

    func disconnect() async {
        _ = try? await sendCommand("QUIT")
        connection?.cancel()
        connection = nil
    }

    // MARK: - Send Email

    func sendEmail(
        from: String,
        to: [String],
        cc: [String] = [],
        bcc: [String] = [],
        subject: String,
        body: String,
        username: String,
        password: String
    ) async throws {
        // Read server greeting
        _ = try await readResponse()

        // EHLO
        let ehloResponse = try await sendCommand("EHLO maia-mail")
        guard ehloResponse.contains("250") else {
            throw SMTPError.handshakeFailed
        }

        // AUTH LOGIN
        let authResponse = try await sendCommand("AUTH LOGIN")
        guard authResponse.contains("334") else {
            throw SMTPError.authenticationFailed
        }

        // Send username (base64)
        let usernameB64 = Data(username.utf8).base64EncodedString()
        let userResponse = try await sendCommand(usernameB64)
        guard userResponse.contains("334") else {
            throw SMTPError.authenticationFailed
        }

        // Send password (base64)
        let passwordB64 = Data(password.utf8).base64EncodedString()
        let passResponse = try await sendCommand(passwordB64)
        guard passResponse.contains("235") else {
            throw SMTPError.authenticationFailed
        }

        // MAIL FROM
        let fromResponse = try await sendCommand("MAIL FROM:<\(from)>")
        guard fromResponse.contains("250") else {
            throw SMTPError.sendFailed("MAIL FROM rejected")
        }

        // RCPT TO for all recipients
        let allRecipients = to + cc + bcc
        for recipient in allRecipients {
            let rcptResponse = try await sendCommand("RCPT TO:<\(recipient)>")
            guard rcptResponse.contains("250") else {
                throw SMTPError.sendFailed("RCPT TO rejected for \(recipient)")
            }
        }

        // DATA
        let dataResponse = try await sendCommand("DATA")
        guard dataResponse.contains("354") else {
            throw SMTPError.sendFailed("DATA command rejected")
        }

        // Build MIME message
        let mimeMessage = buildMIMEMessage(
            from: from,
            to: to,
            cc: cc,
            subject: subject,
            body: body
        )

        // Send message body followed by terminator
        let messageData = mimeMessage + "\r\n.\r\n"
        guard let data = messageData.data(using: .utf8) else {
            throw SMTPError.encodingError
        }
        try await sendData(data)
        let endResponse = try await readResponse()
        guard endResponse.contains("250") else {
            throw SMTPError.sendFailed("Message delivery failed")
        }
    }

    // MARK: - MIME Builder

    private func buildMIMEMessage(
        from: String,
        to: [String],
        cc: [String],
        subject: String,
        body: String
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = dateFormatter.string(from: Date())

        var headers = [
            "From: \(from)",
            "To: \(to.joined(separator: ", "))",
            "Date: \(dateStr)",
            "Subject: \(subject)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=UTF-8",
            "Content-Transfer-Encoding: 8bit",
            "Message-ID: <\(UUID().uuidString)@maia-mail>",
            "X-Mailer: MaiaMail/1.0",
        ]

        if !cc.isEmpty {
            headers.insert("Cc: \(cc.joined(separator: ", "))", at: 2)
        }

        return headers.joined(separator: "\r\n") + "\r\n\r\n" + body
    }

    // MARK: - Network I/O

    private func sendCommand(_ command: String) async throws -> String {
        let fullCommand = command + "\r\n"
        guard let data = fullCommand.data(using: .utf8) else {
            throw SMTPError.encodingError
        }
        try await sendData(data)
        return try await readResponse()
    }

    private func sendData(_ data: Data) async throws {
        guard let connection = connection else {
            throw SMTPError.notConnected
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: SMTPError.sendFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func readResponse() async throws -> String {
        guard let connection = connection else {
            throw SMTPError.notConnected
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { content, _, _, error in
                if let error = error {
                    continuation.resume(throwing: SMTPError.receiveFailed(error.localizedDescription))
                } else if let data = content, let str = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: str)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
}

// MARK: - Errors

enum SMTPError: LocalizedError {
    case connectionFailed(String)
    case connectionCancelled
    case handshakeFailed
    case authenticationFailed
    case notConnected
    case encodingError
    case sendFailed(String)
    case receiveFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "SMTP connection failed: \(msg)"
        case .connectionCancelled: return "SMTP connection cancelled"
        case .handshakeFailed: return "SMTP handshake failed"
        case .authenticationFailed: return "SMTP authentication failed. Check credentials."
        case .notConnected: return "Not connected to SMTP server"
        case .encodingError: return "Failed to encode message"
        case .sendFailed(let msg): return "Send failed: \(msg)"
        case .receiveFailed(let msg): return "Receive failed: \(msg)"
        }
    }
}
