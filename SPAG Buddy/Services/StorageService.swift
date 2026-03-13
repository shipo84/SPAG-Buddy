//
//  StorageService.swift
//  SPAG Buddy
//
//  Generic storage service using UserDefaults
//

import Combine
import Foundation

class StorageService: ObservableObject {
    private let userDefaults = UserDefaults.standard

    func saveData<T: Codable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }

    func loadData<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}
