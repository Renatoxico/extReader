//
//  LoadingErrorView.swift
//  extReader
//
//  Created by Renato Dias on 25/10/25.
//


import SwiftUI

struct LoadingErrorView: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Erro !")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Houve um erro na comunicação com o servidor.")
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
    LoadingErrorView()
}
