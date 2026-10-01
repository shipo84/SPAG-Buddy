#if canImport(Security)
import Foundation
import Security

/// Keychain items that can be read once the iPad has been unlocked after a restart, so answers
/// can sync in the background, and that are never copied to another device by a backup.
final class KeychainStore: SecureStore {
    static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    enum KeychainError: Error, Equatable {
        case status(OSStatus)
    }

    let service: String

    init(service: String = "Digital-Clubhouse.SPAG-Buddy-School.credentials") {
        self.service = service
    }

    func data(forKey key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw KeychainError.status(status)
        }
    }

    func set(_ data: Data, forKey key: String) throws {
        let attributes = Self.itemAttributes(data)
        let status = SecItemUpdate(baseQuery(forKey: key) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let add = baseQuery(forKey: key).merging(attributes) { $1 }
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.status(addStatus) }
        } else if status != errSecSuccess {
            throw KeychainError.status(status)
        }
    }

    func removeValue(forKey key: String) throws {
        try delete(baseQuery(forKey: key))
    }

    func removeAll() throws {
        try delete(baseQuery(forKey: nil))
    }

    /// The protection class stored with an item.
    func accessibility(forKey key: String) throws -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
        return (result as? [String: Any])?[kSecAttrAccessible as String] as? String
    }

    static func itemAttributes(_ data: Data) -> [String: Any] {
        [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility,
        ]
    }

    private func baseQuery(forKey key: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        if let key { query[kSecAttrAccount as String] = key }
        return query
    }

    private func delete(_ query: [String: Any]) throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.status(status) }
    }
}
#endif
