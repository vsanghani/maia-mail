import Foundation
import Security

/// Wrapper around iOS Keychain for secure credential storage.
struct KeychainHelper {

    private static let service = "com.maia.mail"

    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Account-specific helpers

    static func saveAccount(_ account: EmailAccount) -> Bool {
        guard let data = try? JSONEncoder().encode(account) else { return false }
        guard let json = String(data: data, encoding: .utf8) else { return false }
        return save(key: "account_config", value: json)
    }

    static func loadAccount() -> EmailAccount? {
        guard let json = load(key: "account_config"),
              let data = json.data(using: .utf8),
              let account = try? JSONDecoder().decode(EmailAccount.self, from: data) else {
            return nil
        }
        return account
    }

    static func deleteAccount() -> Bool {
        return delete(key: "account_config")
    }
}
