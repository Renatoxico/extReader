//
//  NoHistoryView.swift
//  extReader
//
//  Created by Renato Dias on 09/09/25.
//
import SwiftUI

struct NoHistoryView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No previous sessions")
                .font(.headline)
                .foregroundColor(.secondary)
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
    NoHistoryView()
}
