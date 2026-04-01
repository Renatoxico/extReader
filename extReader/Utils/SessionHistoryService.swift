//
//  SessionHistoryService.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import Foundation
import Security

class SessionHistoryService {
    static let shared = SessionHistoryService()
    private init() { migrateFromUserDefaultsIfNeeded() }

    private let serviceName = "net.renatoxico.extReader"
    private let account = "sessionHistory"

    // MARK: - Public API

    func allItems() -> [String] {
        guard let data = keychainRead(),
              let items = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return items
    }

    func add(_ sessionToken: String) {
        var items = allItems()
        guard !items.contains(sessionToken) else { return }
        items.append(sessionToken)
        keychainWrite(items)
    }

    func delete(_ sessionToken: String) {
        var items = allItems()
        items.removeAll { $0 == sessionToken }
        keychainWrite(items)
    }

    // MARK: - UserDefaults Migration

    private func migrateFromUserDefaultsIfNeeded() {
        let legacyKey = "historyItems"
        guard let legacy = UserDefaults.standard.stringArray(forKey: legacyKey),
              !legacy.isEmpty else { return }
        keychainWrite(legacy)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    // MARK: - Keychain Helpers

    private func baseQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: serviceName,
         kSecAttrAccount as String: account]
    }

    private func keychainRead() -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func keychainWrite(_ items: [String]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        if keychainRead() != nil {
            let update: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(baseQuery() as CFDictionary, update as CFDictionary)
        } else {
            var query = baseQuery()
            query[kSecValueData as String] = data
            query[kSecAttrSynchronizable as String] = false
            SecItemAdd(query as CFDictionary, nil)
        }
    }
}
