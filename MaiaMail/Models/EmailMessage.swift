import Foundation

struct EmailMessage: Identifiable, Codable, Hashable {
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
            date: Date().addingTimeInterval(-Double(index) * 3600),
            isRead: index > 1,
            isStarred: index == 0,
            folder: "INBOX",
            snippet: snippets[i],
            uid: UInt32(index + 1)
        )
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
}
