import Foundation

struct EmailAccount: Codable, Equatable {
    var email: String
    var displayName: String
    var password: String
    var provider: EmailProvider
    var imapHost: String
    var imapPort: Int
    var smtpHost: String
    var smtpPort: Int
    var useSSL: Bool

    enum EmailProvider: String, Codable, CaseIterable, Identifiable {
        case gmail = "Gmail"
        case outlook = "Outlook"
        case yahoo = "Yahoo"
        case icloud = "iCloud"
        case custom = "Custom"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .gmail: return "envelope.fill"
            case .outlook: return "envelope.badge.fill"
            case .yahoo: return "envelope.open.fill"
            case .icloud: return "icloud.fill"
            case .custom: return "gearshape.fill"
            }
        }

        var defaultConfig: (imapHost: String, imapPort: Int, smtpHost: String, smtpPort: Int) {
            switch self {
            case .gmail:
                return ("imap.gmail.com", 993, "smtp.gmail.com", 465)
            case .outlook:
                return ("outlook.office365.com", 993, "smtp.office365.com", 587)
            case .yahoo:
                return ("imap.mail.yahoo.com", 993, "smtp.mail.yahoo.com", 465)
            case .icloud:
                return ("imap.mail.me.com", 993, "smtp.mail.me.com", 587)
            case .custom:
                return ("", 993, "", 465)
            }
        }
    }

    static func withProvider(_ provider: EmailProvider) -> EmailAccount {
        let config = provider.defaultConfig
        return EmailAccount(
            email: "",
            displayName: "",
            password: "",
            provider: provider,
            imapHost: config.imapHost,
            imapPort: config.imapPort,
            smtpHost: config.smtpHost,
            smtpPort: config.smtpPort,
            useSSL: true
        )
    }
}
