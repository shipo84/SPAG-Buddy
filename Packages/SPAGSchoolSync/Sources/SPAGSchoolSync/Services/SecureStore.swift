import Foundation

/// Small secrets kept outside SwiftData. The School app uses `KeychainStore`; tests use `InMemorySecureStore`.
protocol SecureStore: AnyObject {
    func data(forKey key: String) throws -> Data?
    func set(_ data: Data, forKey key: String) throws
    func removeValue(forKey key: String) throws
    /// Removes every item this app has stored.
    func removeAll() throws
}

final class InMemorySecureStore: SecureStore {
    private(set) var values: [String: Data] = [:]

    func data(forKey key: String) throws -> Data? { values[key] }
    func set(_ data: Data, forKey key: String) throws { values[key] = data }
    func removeValue(forKey key: String) throws { values[key] = nil }
    func removeAll() throws { values = [:] }
}
