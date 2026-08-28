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
                if !auth.isAuthReady {
                    ZStack {
                        BackgroundView()
                        ProgressView("Verificando sessão...")
                            .tint(.green)
                            .foregroundColor(.white)
                    }
                } else if auth.isAuthenticated {
                    HomeView()
                        .environmentObject(fileSelectionManager)
                } else {
                    LoginView()
                }
            }
            .environment(\.colorScheme, .dark)
            .environmentObject(auth)
            .onOpenURL { url in
                if auth.handleURL(url) {
                    return
                } else if url.scheme == "extreader" {
                    return
                } else {
                    fileSelectionManager.addFile(url)
                }
            }
        }
    }
}
