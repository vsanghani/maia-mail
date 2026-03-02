import Foundation
import Network

/// IMAP client using Apple's Network framework with TLS support.
/// Handles email retrieval, folder listing, and flag management.
actor IMAPService {

    private var connection: NWConnection?
    private let host: String
    private let port: Int
    private let useSSL: Bool
    private var tagCounter: Int = 0
    private var isAuthenticated: Bool = false

    init(host: String, port: Int, useSSL: Bool = true) {
        self.host = host
        self.port = port
        self.useSSL = useSSL
    }

    // MARK: - Connection

    func connect() async throws {
        let tlsOptions = NWProtocolTLS.Options()
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 15

        let params: NWParameters
        if useSSL {
            params = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        } else {
            params = NWParameters(tls: nil, tcp: tcpOptions)
        }

        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

        connection = NWConnection(host: nwHost, port: nwPort, using: params)

        return try await withCheckedThrowingContinuation { continuation in
            connection?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: IMAPError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    continuation.resume(throwing: IMAPError.connectionCancelled)
                default:
                    break
                }
            }
            connection?.start(queue: .global(qos: .userInitiated))
        }
    }

    func disconnect() async {
        if isAuthenticated {
            _ = try? await sendCommand("LOGOUT")
        }
        connection?.cancel()
        connection = nil
        isAuthenticated = false
    }

    // MARK: - Authentication

    func login(email: String, password: String) async throws {
        // Read server greeting
        _ = try await readResponse()
        let escapedPassword = password.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let response = try await sendCommand("LOGIN \"\(email)\" \"\(escapedPassword)\"")
        guard response.contains("OK") else {
            throw IMAPError.authenticationFailed
        }
        isAuthenticated = true
    }

    // MARK: - Mailbox Operations

    func listFolders() async throws -> [String] {
        let response = try await sendCommand("LIST \"\" \"*\"")
        var folders: [String] = []
        let lines = response.components(separatedBy: "\r\n")
        for line in lines {
            if line.contains("* LIST") {
                // Parse: * LIST (\Flags) "delimiter" "folder-name"
                if let nameRange = line.range(of: "\" ", options: .backwards) {
                    var name = String(line[nameRange.upperBound...])
                    name = name.trimmingCharacters(in: .whitespaces)
                    if name.hasPrefix("\"") && name.hasSuffix("\"") {
                        name = String(name.dropFirst().dropLast())
                    }
                    folders.append(name)
                }
            }
        }
        return folders
    }

    func selectFolder(_ folder: String) async throws -> Int {
        let response = try await sendCommand("SELECT \"\(folder)\"")
        // Parse EXISTS count
        var count = 0
        let lines = response.components(separatedBy: "\r\n")
        for line in lines {
            if line.contains("EXISTS") {
                let parts = line.components(separatedBy: " ")
                if let idx = parts.firstIndex(of: "EXISTS"), idx > 0 {
                    count = Int(parts[idx - 1].replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
                }
            }
        }
        return count
    }

    // MARK: - Message Fetching

    func fetchMessages(folder: String, limit: Int = 50) async throws -> [EmailMessage] {
        let messageCount = try await selectFolder(folder)
        guard messageCount > 0 else { return [] }

        let start = max(1, messageCount - limit + 1)
        let range = "\(start):\(messageCount)"

        let response = try await sendCommand("FETCH \(range) (UID FLAGS INTERNALDATE RFC822.HEADER BODY.PEEK[TEXT])")
        return parseMessages(from: response, folder: folder)
    }

    func fetchMessageBody(folder: String, uid: UInt32) async throws -> String {
        _ = try await selectFolder(folder)
        let response = try await sendCommand("UID FETCH \(uid) (BODY[TEXT])")
        return parseBody(from: response)
    }

    // MARK: - Flag Operations

    func markAsRead(folder: String, uid: UInt32) async throws {
        _ = try await selectFolder(folder)
        _ = try await sendCommand("UID STORE \(uid) +FLAGS (\\Seen)")
    }

    func markAsUnread(folder: String, uid: UInt32) async throws {
        _ = try await selectFolder(folder)
        _ = try await sendCommand("UID STORE \(uid) -FLAGS (\\Seen)")
    }

    func toggleStar(folder: String, uid: UInt32, star: Bool) async throws {
        _ = try await selectFolder(folder)
        let op = star ? "+FLAGS" : "-FLAGS"
        _ = try await sendCommand("UID STORE \(uid) \(op) (\\Flagged)")
    }

    func deleteMessage(folder: String, uid: UInt32) async throws {
        _ = try await selectFolder(folder)
        _ = try await sendCommand("UID STORE \(uid) +FLAGS (\\Deleted)")
        _ = try await sendCommand("EXPUNGE")
    }

    // MARK: - Network I/O

    private func nextTag() -> String {
        tagCounter += 1
        return "A\(String(format: "%04d", tagCounter))"
    }

    private func sendCommand(_ command: String) async throws -> String {
        let tag = nextTag()
        let fullCommand = "\(tag) \(command)\r\n"

        guard let data = fullCommand.data(using: .utf8) else {
            throw IMAPError.encodingError
        }

        try await sendData(data)
        return try await readTaggedResponse(tag: tag)
    }

    private func sendData(_ data: Data) async throws {
        guard let connection = connection else {
            throw IMAPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: IMAPError.sendFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func readResponse() async throws -> String {
        guard let connection = connection else {
            throw IMAPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { content, _, _, error in
                if let error = error {
                    continuation.resume(throwing: IMAPError.receiveFailed(error.localizedDescription))
                } else if let data = content, let str = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: str)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    private func readTaggedResponse(tag: String) async throws -> String {
        var fullResponse = ""
        let timeout: TimeInterval = 30
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let chunk = try await readResponse()
            fullResponse += chunk

            if fullResponse.contains("\(tag) OK") || fullResponse.contains("\(tag) NO") || fullResponse.contains("\(tag) BAD") {
                break
            }
        }

        if fullResponse.contains("\(tag) NO") || fullResponse.contains("\(tag) BAD") {
            throw IMAPError.commandFailed(fullResponse)
        }

        return fullResponse
    }

    // MARK: - Parsing

    private func parseMessages(from response: String, folder: String) -> [EmailMessage] {
        var messages: [EmailMessage] = []
        let sections = response.components(separatedBy: "* ")

        for section in sections {
            guard section.contains("FETCH") else { continue }

            var uid: UInt32 = 0
            var isRead = false
            var isStarred = false
            var subject = "(No Subject)"
            var from = EmailAddress(name: nil, address: "unknown@unknown.com")
            var to: [EmailAddress] = []
            var date = Date()
            var body = ""

            // Parse UID
            if let uidRange = section.range(of: "UID ") {
                let afterUID = section[uidRange.upperBound...]
                let uidStr = afterUID.prefix(while: { $0.isNumber })
                uid = UInt32(uidStr) ?? 0
            }

            // Parse FLAGS
            if let flagsRange = section.range(of: "FLAGS (") {
                let afterFlags = section[flagsRange.upperBound...]
                if let endRange = afterFlags.range(of: ")") {
                    let flags = String(afterFlags[..<endRange.lowerBound])
                    isRead = flags.contains("\\Seen")
                    isStarred = flags.contains("\\Flagged")
                }
            }

            // Parse headers
            let headerSection = section

            // Subject
            if let subjectRange = headerSection.range(of: "Subject: ", options: .caseInsensitive) {
                let afterSubject = headerSection[subjectRange.upperBound...]
                if let endOfLine = afterSubject.firstIndex(of: "\r") ?? afterSubject.firstIndex(of: "\n") {
                    subject = String(afterSubject[..<endOfLine]).trimmingCharacters(in: .whitespaces)
                }
            }

            // From
            if let fromRange = headerSection.range(of: "From: ", options: .caseInsensitive) {
                let afterFrom = headerSection[fromRange.upperBound...]
                if let endOfLine = afterFrom.firstIndex(of: "\r") ?? afterFrom.firstIndex(of: "\n") {
                    let fromStr = String(afterFrom[..<endOfLine])
                    from = parseEmailAddress(fromStr)
                }
            }

            // To
            if let toRange = headerSection.range(of: "To: ", options: .caseInsensitive) {
                let afterTo = headerSection[toRange.upperBound...]
                if let endOfLine = afterTo.firstIndex(of: "\r") ?? afterTo.firstIndex(of: "\n") {
                    let toStr = String(afterTo[..<endOfLine])
                    to = [parseEmailAddress(toStr)]
                }
            }

            // Date
            if let dateRange = headerSection.range(of: "Date: ", options: .caseInsensitive) {
                let afterDate = headerSection[dateRange.upperBound...]
                if let endOfLine = afterDate.firstIndex(of: "\r") ?? afterDate.firstIndex(of: "\n") {
                    let dateStr = String(afterDate[..<endOfLine]).trimmingCharacters(in: .whitespaces)
                    date = parseIMAPDate(dateStr)
                }
            }

            // Body text
            if let bodyStart = section.range(of: "BODY[TEXT]") {
                let afterBody = section[bodyStart.upperBound...]
                // Skip the literal marker {size}
                if let braceEnd = afterBody.range(of: "\r\n") {
                    body = String(afterBody[braceEnd.upperBound...])
                    // Trim trailing fetch data
                    if let endParen = body.range(of: ")\r\n", options: .backwards) {
                        body = String(body[..<endParen.lowerBound])
                    }
                }
            }

            let snippet = String(body.prefix(150))
                .replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let message = EmailMessage(
                id: "\(folder)-\(uid)",
                from: from,
                to: to,
                cc: [],
                bcc: [],
                subject: subject,
                body: body,
                date: date,
                isRead: isRead,
                isStarred: isStarred,
                folder: folder,
                snippet: snippet,
                uid: uid
            )

            if uid > 0 {
                messages.append(message)
            }
        }

        return messages.sorted { $0.date > $1.date }
    }

    private func parseBody(from response: String) -> String {
        // Extract body text from FETCH response
        if let bodyStart = response.range(of: "BODY[TEXT]") {
            let afterBody = response[bodyStart.upperBound...]
            if let braceEnd = afterBody.range(of: "\r\n") {
                var body = String(afterBody[braceEnd.upperBound...])
                if let endParen = body.range(of: ")\r\n", options: .backwards) {
                    body = String(body[..<endParen.lowerBound])
                }
                return body.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    private func parseEmailAddress(_ str: String) -> EmailAddress {
        let trimmed = str.trimmingCharacters(in: .whitespaces)

        // Format: "Name" <email@domain.com> or Name <email@domain.com>
        if let angleStart = trimmed.range(of: "<"),
           let angleEnd = trimmed.range(of: ">") {
            let address = String(trimmed[angleStart.upperBound..<angleEnd.lowerBound])
            var name = String(trimmed[..<angleStart.lowerBound])
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if name.isEmpty { name = address }
            return EmailAddress(name: name, address: address)
        }

        return EmailAddress(name: nil, address: trimmed)
    }

    private func parseIMAPDate(_ dateStr: String) -> Date {
        let formatters: [DateFormatter] = {
            let formats = [
                "EEE, dd MMM yyyy HH:mm:ss Z",
                "dd MMM yyyy HH:mm:ss Z",
                "EEE, dd MMM yyyy HH:mm:ss z",
                "dd MMM yyyy HH:mm:ss z",
                "EEE, d MMM yyyy HH:mm:ss Z",
            ]
            return formats.map { format -> DateFormatter in
                let f = DateFormatter()
                f.dateFormat = format
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return Date()
    }
}

// MARK: - Errors

enum IMAPError: LocalizedError {
    case connectionFailed(String)
    case connectionCancelled
    case authenticationFailed
    case notConnected
    case encodingError
    case sendFailed(String)
    case receiveFailed(String)
    case commandFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .connectionCancelled: return "Connection was cancelled"
        case .authenticationFailed: return "Authentication failed. Check your email and password."
        case .notConnected: return "Not connected to server"
        case .encodingError: return "Failed to encode command"
        case .sendFailed(let msg): return "Send failed: \(msg)"
        case .receiveFailed(let msg): return "Receive failed: \(msg)"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .timeout: return "Connection timed out"
        }
    }
}
