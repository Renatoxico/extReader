//
//  SessionHistoryService.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//

import Foundation

class SessionHistoryService {
    static let shared = SessionHistoryService()
    private init() {}

    private let key = "historyItems"

    func allItems() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(_ sessionToken: String) {
        var items = allItems()
        items.append(sessionToken)
        UserDefaults.standard.set(items, forKey: key)
    }

    func delete(_ sessionToken: String) {
        var items = allItems()
        items.removeAll { $0 == sessionToken }
        UserDefaults.standard.set(items, forKey: key)
    }
}
