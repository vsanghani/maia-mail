import Foundation

struct EmailMessage: Identifiable, Hashable {
    static func == (lhs: EmailMessage, rhs: EmailMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String
    var from: EmailAddress
    var to: [EmailAddress]
    var cc: [EmailAddress]
    var bcc: [EmailAddress]
    var subject: String
    var body: String
    var htmlBody: String?
    var date: Date
    var isRead: Bool
    var isStarred: Bool
    var folder: String
    var snippet: String
    var uid: UInt32
    /// Stored only on-device; never fetched from or synced to IMAP.
    var isSimulated: Bool

    var senderInitials: String {
        let parts = from.name?.split(separator: " ") ?? from.address.split(separator: "@")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(parts.first?.prefix(2) ?? "??").uppercased()
    }

    var formattedDate: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }

        return formatter.string(from: date)
    }

    static func preview(index: Int = 0) -> EmailMessage {
        let senders = [
            EmailAddress(name: "Sarah Chen", address: "sarah.chen@example.com"),
            EmailAddress(name: "Alex Rivera", address: "alex.r@company.co"),
            EmailAddress(name: "GitHub", address: "notifications@github.com"),
            EmailAddress(name: "Jordan Taylor", address: "jordan.t@startup.io"),
            EmailAddress(name: "Newsletter", address: "hello@techdigest.com"),
        ]
        let subjects = [
            "Re: Q1 Planning Meeting Notes",
            "Design Review — New Dashboard",
            "[maia-mail] New pull request #42",
            "Onboarding documents ready",
            "This Week in Tech: AI Breakthroughs",
        ]
        let snippets = [
            "Thanks for sharing the notes from yesterday's meeting. I had a few thoughts on the timeline...",
            "Hey team, I've attached the latest mockups for the dashboard redesign. Let me know your thoughts...",
            "dependabot opened a new pull request: Bump swift-nio from 2.58.0 to 2.62.0...",
            "Hi! Your onboarding documents are ready for review. Please sign and return by Friday...",
            "This week's top stories: GPT-5 announced, Apple reveals new M4 chip, and more...",
        ]

        let i = index % senders.count
        return EmailMessage(
            id: UUID().uuidString,
            from: senders[i],
            to: [EmailAddress(name: "Me", address: "me@example.com")],
            cc: [],
            bcc: [],
            subject: subjects[i],
            body: snippets[i] + "\n\nBest regards,\n\(senders[i].name ?? "Sender")",
            htmlBody: nil,
            date: Date().addingTimeInterval(-Double(index) * 3600),
            isRead: index > 1,
            isStarred: index == 0,
            folder: "INBOX",
            snippet: snippets[i],
            uid: UInt32(index + 1),
            isSimulated: false
        )
    }
}

extension EmailMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, from, to, cc, bcc, subject, body, htmlBody, date, isRead, isStarred, folder, snippet, uid, isSimulated
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        from = try c.decode(EmailAddress.self, forKey: .from)
        to = try c.decode([EmailAddress].self, forKey: .to)
        cc = try c.decodeIfPresent([EmailAddress].self, forKey: .cc) ?? []
        bcc = try c.decodeIfPresent([EmailAddress].self, forKey: .bcc) ?? []
        subject = try c.decode(String.self, forKey: .subject)
        body = try c.decode(String.self, forKey: .body)
        htmlBody = try c.decodeIfPresent(String.self, forKey: .htmlBody)
        date = try c.decode(Date.self, forKey: .date)
        isRead = try c.decode(Bool.self, forKey: .isRead)
        isStarred = try c.decode(Bool.self, forKey: .isStarred)
        folder = try c.decode(String.self, forKey: .folder)
        snippet = try c.decode(String.self, forKey: .snippet)
        uid = try c.decode(UInt32.self, forKey: .uid)
        isSimulated = try c.decodeIfPresent(Bool.self, forKey: .isSimulated) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(from, forKey: .from)
        try c.encode(to, forKey: .to)
        try c.encode(cc, forKey: .cc)
        try c.encode(bcc, forKey: .bcc)
        try c.encode(subject, forKey: .subject)
        try c.encode(body, forKey: .body)
        try c.encodeIfPresent(htmlBody, forKey: .htmlBody)
        try c.encode(date, forKey: .date)
        try c.encode(isRead, forKey: .isRead)
        try c.encode(isStarred, forKey: .isStarred)
        try c.encode(folder, forKey: .folder)
        try c.encode(snippet, forKey: .snippet)
        try c.encode(uid, forKey: .uid)
        try c.encode(isSimulated, forKey: .isSimulated)
    }
}

struct EmailAddress: Codable, Equatable, Hashable {
    var name: String?
    var address: String

    var displayName: String {
        name ?? address
    }

    var formatted: String {
        if let name = name {
            return "\(name) <\(address)>"
        }
        return address
    }

    /// Parses one line such as `alice@example.com` or `Alice <alice@example.com>`.
    static func parseSingle(_ raw: String) -> EmailAddress? {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return nil }

        if let open = line.lastIndex(of: "<"),
           let close = line.firstIndex(of: ">"),
           open < close {
            let namePart = line[..<open].trimmingCharacters(in: .whitespaces)
            let addrStart = line.index(after: open)
            let addr = line[addrStart..<close].trimmingCharacters(in: .whitespaces)
            guard !addr.isEmpty else { return nil }
            let name: String? = namePart.isEmpty ? nil : String(namePart)
            return EmailAddress(name: name, address: String(addr))
        }

        return EmailAddress(name: nil, address: line)
    }

    /// One recipient per line; blank lines ignored. Lines can use `Name <email>` form.
    static func parseRecipientList(_ text: String) -> [EmailAddress] {
        text.components(separatedBy: .newlines)
            .compactMap { parseSingle($0) }
    }
}
