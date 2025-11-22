//
//  extReaderApp.swift
//  extReader
//
//  Created by Renato Dias on 25/05/25.
//

import SwiftUI

@main
struct extReaderApp: App {
    @StateObject private var fileSelectorContraption = FileSelectorContraption()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.colorScheme, .dark)
                .environmentObject(fileSelectorContraption)
                .onOpenURL { url in
                    fileSelectorContraption.addFile(url)
                }
        }
    }
}
