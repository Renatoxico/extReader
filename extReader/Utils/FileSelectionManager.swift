//
//  FileSelectionManager.swift
//  extReader
//
//  Created by Renato Dias on 26/10/25.
//

import Foundation


class FileSelectionManager: ObservableObject {
    @Published var selectedFiles: [URL] = []

    func addFile(_ url: URL) {
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard accessGranted else {
            print("Couldn't access file")
            return
        }
        
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }
        let file = documentsDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            try FileManager.default.copyItem(at: url, to: file)
            DispatchQueue.main.async {
                self.selectedFiles.append(file)
            }
        } catch {
            print("Couldn't copy file: \(error)")
            return
        }
    }
}
