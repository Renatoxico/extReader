//
//  SupabaseConfig.swift
//  extReader
//
//  Created by Renato Dias on 26/03/26.
//
//  Values are injected at build time from Secrets.xcconfig via Info.plist.
//  See Secrets.xcconfig.example for setup instructions.
//

import Foundation

enum SupabaseConfig {
    // ⚠️ Stored without https:// in xcconfig because // is a comment delimiter.
    static let url: String = {
        guard let host = Bundle.main.infoDictionary?["SupabaseURL"] as? String,
              !host.isEmpty, !host.hasPrefix("your-"), !host.hasPrefix("$(") else {
            fatalError("SupabaseURL is not configured. Copy Secrets.xcconfig.example → Secrets.xcconfig and fill in your values.")
        }
        return "https://\(host)"
    }()

    static let anonKey: String = {
        guard let value = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String,
              !value.isEmpty, !value.hasPrefix("your_"), !value.hasPrefix("$(") else {
            fatalError("SupabaseAnonKey is not configured — xcconfig may not be linked to the project. Go to: Project → Info → Configurations → set Secrets for Debug & Release.")
        }
        return value
    }()
}
