//
//  NoFilesView.swift
//  extReader
//
//  Created by Renato Dias on 17/06/25.
//

import SwiftUI

struct NoFilesView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No files selected")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the button above to select PDF files")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    NoFilesView()
}
