//
//  extReaderApp.swift
//  extReader
//
//  Created by Renato Dias on 25/05/25.
//

import SwiftUI

@main
struct extReaderApp: App {
    @StateObject private var fileSelectionManager = FileSelectionManager()
    @StateObject private var auth = AuthService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    HomeView()
                        .environmentObject(fileSelectionManager)
                } else {
                    LoginView()
                }
            }
            .environment(\.colorScheme, .dark)
            .environmentObject(auth)
            .onOpenURL { url in
                // Route auth-callback URLs to Supabase; everything else is a file
                if url.scheme == "extreader" {
                    auth.handleURL(url)
                } else {
                    fileSelectionManager.addFile(url)
                }
            }
        }
    }
}
