import Foundation
import SwiftUI

struct EmailFolder: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    var unreadCount: Int
    let icon: String
    let type: FolderType

    enum FolderType: String, Codable, CaseIterable {
        case inbox = "INBOX"
        case sent = "Sent"
        case drafts = "Drafts"
        case trash = "Trash"
        case spam = "Spam"
        case starred = "Starred"
        case archive = "Archive"
        case custom = "Custom"
    }

    static let defaultFolders: [EmailFolder] = [
        EmailFolder(id: "inbox", name: "Inbox", path: "INBOX", unreadCount: 0, icon: "tray.fill", type: .inbox),
        EmailFolder(id: "starred", name: "Starred", path: "Starred", unreadCount: 0, icon: "star.fill", type: .starred),
        EmailFolder(id: "sent", name: "Sent", path: "Sent", unreadCount: 0, icon: "paperplane.fill", type: .sent),
        EmailFolder(id: "drafts", name: "Drafts", path: "Drafts", unreadCount: 0, icon: "doc.fill", type: .drafts),
        EmailFolder(id: "spam", name: "Spam", path: "Spam", unreadCount: 0, icon: "xmark.octagon.fill", type: .spam),
        EmailFolder(id: "trash", name: "Trash", path: "Trash", unreadCount: 0, icon: "trash.fill", type: .trash),
        EmailFolder(id: "archive", name: "Archive", path: "Archive", unreadCount: 0, icon: "archivebox.fill", type: .archive),
    ]
}
