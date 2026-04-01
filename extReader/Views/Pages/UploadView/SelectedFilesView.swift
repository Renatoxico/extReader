//
//  FileView.swift
//  extReader
//
//  Created by Renato Dias on 25/06/25.
//

import SwiftUI

struct SelectedFilesView: View {
    @Binding var selectedFiles: [URL]
    var body: some View {
        if !selectedFiles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Arquivos Selecionados:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, fileURL in
                    HStack {
                        // PDF Icon
                        Image(systemName: "doc.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        // File Name
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileURL.lastPathComponent)
                                .font(.body)
                                .lineLimit(1)
                            
                            Text(fileURL.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Remove Button
                        Button(action: {
                            selectedFiles.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        } 
    }
}
