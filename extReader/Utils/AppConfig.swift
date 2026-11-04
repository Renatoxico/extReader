//
//  AppConfig.swift
//  extReader
//

import Foundation

enum AppConfig {
    static let apiBaseURL: URL = {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "SOMAI_API_BASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !configured.isEmpty, let url = URL(string: configured),
           ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil { return url }
        return URL(string: "https://api.somai.renatoxico.net")!
    }()
    static let privacyPolicyURL = URL(string: "https://somai.renatoxico.net/privacy")!
    static let termsOfUseURL = URL(string: "https://somai.renatoxico.net/terms")!
}
