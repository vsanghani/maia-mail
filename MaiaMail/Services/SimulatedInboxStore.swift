import Foundation

/// Persists on-device-only inbox entries (not backed by IMAP).
enum SimulatedInboxStore {
    private static let keyPrefix = "maia.simulatedInbox."

    private static func storageKey(accountEmail: String) -> String {
        keyPrefix + accountEmail.lowercased()
    }

    static func load(accountEmail: String) -> [EmailMessage] {
        let key = storageKey(accountEmail: accountEmail)
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([EmailMessage].self, from: data)) ?? []
    }

    static func save(_ messages: [EmailMessage], accountEmail: String) {
        let key = storageKey(accountEmail: accountEmail)
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func clear(accountEmail: String) {
        UserDefaults.standard.removeObject(forKey: storageKey(accountEmail: accountEmail))
    }
}
