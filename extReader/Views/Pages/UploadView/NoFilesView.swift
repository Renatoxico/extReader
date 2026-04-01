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
            
            Text("Nenhum arquivo selecionado")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Toque para selecionar arquivos PDF")
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
